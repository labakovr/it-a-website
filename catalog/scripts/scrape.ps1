<#
  Scrapes the selected equipment categories from ipmatika.by and writes a
  structured JSON snapshot to catalog/data/catalog.json, downloading one
  product photo per SKU into assets/img/catalog/<category>/<subcategory>/.

  Only the categories/subcategories that АйТи Аналитикс actually resells are
  included here (mirrors the selection already used on the sister site
  dataplus.by/catalog/) — not the vendor's full catalog.

  Run from repo root:  pwsh -File catalog/scripts/scrape.ps1
  (Windows PowerShell 5.1 and PowerShell 7/pwsh both work.)
#>

$ErrorActionPreference = "Stop"

$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot "../..")
$dataDir    = Join-Path $repoRoot "catalog/data"
$imgRoot    = Join-Path $repoRoot "assets/img/catalog"
$sourceHost = "https://ipmatika.by"

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

# ---- category tree we mirror from dataplus.by/catalog/ -------------------
$tree = @(
  @{ slug = "ip-telefony"; name = "IP-телефоны"; sub = @(
      @{ slug = "desktop";        name = "Настольные телефоны";      path = "desktop" }
      @{ slug = "dect";           name = "DECT-экосистема Yealink";  path = "dect" }
      @{ slug = "videophones";    name = "Видеотелефоны";            path = "videophones" }
      @{ slug = "audioconference";name = "Конференц-телефоны";       path = "audioconference" }
      @{ slug = "hotel-phone";    name = "Отельные телефоны";        path = "hotel-phone" }
      @{ slug = "wifi-telefony";  name = "Wi-Fi-телефоны";           path = "wifi-telefony" }
  )},
  @{ slug = "ip-ats"; name = "IP-АТС"; sub = @(
      @{ slug = "yeastar-pse";       name = "IP-АТС Yeastar PSE";       path = "ip-ats-yeastar-serii-pse"; group = "Yeastar PSE" }
      @{ slug = "licenses-enterprise"; name = "Лицензии Enterprise";    path = "litsenzii-enterprise";     group = "Yeastar PSE" }
      @{ slug = "licenses-ultimate";   name = "Лицензии Ultimate";      path = "litsenzii-ultimate";       group = "Yeastar PSE" }
      @{ slug = "p-series";          name = "IP-АТС серии P";           path = "ip-ats";                   group = "Yeastar серии P" }
      @{ slug = "licenses-p-series"; name = "Лицензии серии P";         path = "licenses-p-series";        group = "Yeastar серии P" }
      @{ slug = "pbx-module";        name = "Модули расширения";        path = "pbx-module" }
      @{ slug = "software-module";   name = "Модули ПО IP-АТС";         path = "software-module" }
  )},
  @{ slug = "voip-shlyuzy"; name = "VoIP-шлюзы"; sub = @(
      @{ slug = "fxs-fxo";   name = "FXS/FXO-шлюзы"; path = "voip-fxs-fxo" }
      @{ slug = "lte";       name = "LTE-шлюзы";     path = "lte-shlyuzy" }
  )},
  @{ slug = "garnitury"; name = "Гарнитуры"; sub = @(
      @{ slug = "yealink-bluetooth"; name = "Yealink — беспроводные Bluetooth"; path = "besprovodnye-bluetooth"; group = "Yealink" }
      @{ slug = "yealink-dect";      name = "Yealink — беспроводные DECT";      path = "besprovodnye-garnitury"; group = "Yealink" }
      @{ slug = "yealink-wired-qd";  name = "Yealink — проводные QD-RJ9";       path = "provodnye-qd-rj9";       group = "Yealink" }
      @{ slug = "yealink-wired-usb"; name = "Yealink — проводные USB";          path = "provodnye-usb";          group = "Yealink" }
      @{ slug = "yealink-accessories"; name = "Yealink — аксессуары для гарнитур"; path = "aksessuary-dlya-garnitur"; group = "Yealink" }
      @{ slug = "vt-bluetooth"; name = "VT — беспроводные Bluetooth"; path = "bluetooth";  group = "VT" }
      @{ slug = "vt-dect";      name = "VT — беспроводные DECT";      path = "dect-";       group = "VT" }
      @{ slug = "vt-wired";     name = "VT — проводные";              path = "provodnye";   group = "VT" }
      @{ slug = "vt-rugged";    name = "VT — защищённые гарнитуры";   path = "garnitury-zashchishchyennye"; group = "VT" }
  )}
)

function Get-Win1251Html($url) {
  $req = [System.Net.WebRequest]::Create($url)
  $req.UserAgent = "Mozilla/5.0 (compatible; it-a.by catalog sync)"
  $req.Timeout = 30000
  try {
    $resp = $req.GetResponse()
  } catch [System.Net.WebException] {
    $resp = $_.Exception.Response
    if (-not $resp) { throw }
  }
  $stream = $resp.GetResponseStream()
  $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::GetEncoding(1251))
  $html = $reader.ReadToEnd()
  $reader.Close()
  $resp.Close()
  return $html
}

function Clean-Text($s) {
  if (-not $s) { return "" }
  $s = $s -replace "&nbsp;", " "
  $s = $s -replace "&amp;", "&"
  $s = $s -replace "&quot;", '"'
  $s = $s -replace "\s+", " "
  return $s.Trim()
}

function Parse-Price($chunk) {
  $m = [regex]::Match($chunk, 'class="(?:price|catalog_price_value)"[^>]*>\s*(?:<b>)?\s*([\d\s ]+)\s*бел\.\s*руб')
  if ($m.Success) {
    $digits = ($m.Groups[1].Value -replace "[^\d]", "")
    if ($digits) { return [int]$digits }
  }
  return $null
}

function Parse-Listing($html, $baseUrl) {
  $items = @()
  $chunks = $html -split '<div class="catalog_item">'
  for ($i = 1; $i -lt $chunks.Length; $i++) {
    $chunk = $chunks[$i]
    $h2 = [regex]::Match($chunk, '<h2><a href="([^"]+)"[^>]*>([^<]+)</a></h2>')
    if (-not $h2.Success) { continue }
    $href = $h2.Groups[1].Value
    $name = Clean-Text $h2.Groups[2].Value
    $imgM = [regex]::Match($chunk, '<img[^>]+src="([^"]+)"')
    $img = if ($imgM.Success) { $imgM.Groups[1].Value } else { $null }
    $price = Parse-Price $chunk
    $items += [ordered]@{
      name  = $name
      url   = (New-Object System.Uri((New-Object System.Uri($baseUrl)), $href)).AbsoluteUri
      image = if ($img) { (New-Object System.Uri((New-Object System.Uri($baseUrl)), $img)).AbsoluteUri } else { $null }
      price = $price
    }
  }
  return $items
}

function Parse-Detail($html) {
  $result = [ordered]@{
    description = ""
    specs       = ""
    price       = $null
    images      = @()
  }

  $h1 = [regex]::Match($html, '<h1>([^<]+)</h1>')
  if ($h1.Success) { $result.name = Clean-Text $h1.Groups[1].Value }

  # Description: content of .catalog_descr up to the nested .catalog_price block
  $descM = [regex]::Match($html, '<div class="catalog_descr">(.*?)<div class="catalog_price">', 'Singleline')
  if ($descM.Success) {
    $desc = $descM.Groups[1].Value
    $desc = $desc -replace '<p style="text-align: justify">', ''
    $desc = $desc -replace 'style="[^"]*"', ''
    $desc = $desc -replace '<p>\s*</p>', ''
    $desc = $desc -replace '<span>\s*</span>', ''
    $result.description = $desc.Trim()
  }

  $priceM = [regex]::Match($html, 'catalog_price_value"><b>\s*([\d\s]+)\s*бел\.\s*руб')
  if ($priceM.Success) {
    $digits = ($priceM.Groups[1].Value -replace "[^\d]", "")
    if ($digits) { $result.price = [int]$digits }
  }

  # Specs: TECHLINK tab content
  $specM = [regex]::Match($html, 'catalog_item_text copyable TECHLINK">\s*<table[^>]*>\s*<tbody>\s*<tr>\s*<td[^>]*>(.*?)</td>\s*</tr>\s*</tbody>\s*</table>', 'Singleline')
  if ($specM.Success) {
    $result.specs = $specM.Groups[1].Value.Trim()
  }

  # Gallery images (id="wares_bigN")
  $imgMatches = [regex]::Matches($html, '<img src="([^"]+)"[^>]*id="wares_big\d+"')
  foreach ($m in $imgMatches) { $result.images += $m.Groups[1].Value }
  if ($result.images.Count -eq 0) {
    $og = [regex]::Match($html, '<meta property="og:image" content="([^"]+)"')
    if ($og.Success) { $result.images += $og.Groups[1].Value }
  }

  return $result
}

function Slugify($url) {
  # last non-empty path segment of an ipmatika product url
  $u = [System.Uri]$url
  $segs = $u.AbsolutePath.Trim('/') -split '/'
  return $segs[-1]
}

function Get-RealExtension($bytes, $fallback) {
  if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50) { return ".png" }
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8) { return ".jpg" }
  if ($bytes.Length -ge 6 -and $bytes[0] -eq 0x47 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46) { return ".gif" }
  if ($bytes.Length -ge 12 -and $bytes[8] -eq 0x57 -and $bytes[9] -eq 0x45 -and $bytes[10] -eq 0x42 -and $bytes[11] -eq 0x50) { return ".webp" }
  return $fallback
}

function Download-Image($url, $destPathNoExt, $fallbackExt) {
  # Returns the relative path actually written (extension corrected to match
  # real file content, since ipmatika's resize_cache endpoint sometimes
  # serves PNG bytes behind a *.jpg-looking URL).
  try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (compatible; it-a.by catalog sync)")
    $bytes = $wc.DownloadData($url)
    $ext = Get-RealExtension $bytes $fallbackExt
    $destPath = "$destPathNoExt$ext"
    New-Item -ItemType Directory -Force -Path (Split-Path $destPath) | Out-Null
    if (-not (Test-Path $destPath)) {
      [System.IO.File]::WriteAllBytes($destPath, $bytes)
    }
    return $destPath
  } catch {
    Write-Warning "Image download failed: $url -> $($_.Exception.Message)"
    return $null
  }
}

$catalog = [ordered]@{
  generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  categories  = @()
}

foreach ($cat in $tree) {
  Write-Host "== Category: $($cat.name) =="
  $catNode = [ordered]@{ slug = $cat.slug; name = $cat.name; subcategories = @() }

  foreach ($sub in $cat.sub) {
    $listUrl = "$sourceHost/products/$($sub.path)/"
    Write-Host "  -- $($sub.name) ($listUrl)"
    try {
      $html = Get-Win1251Html $listUrl
    } catch {
      Write-Warning "    Failed to fetch listing: $($_.Exception.Message)"
      continue
    }
    $items = Parse-Listing $html $listUrl
    if ($items.Count -eq 0) {
      Write-Host "    (no products currently listed — skipped)"
      continue
    }

    $products = @()
    foreach ($item in $items) {
      $slug = Slugify $item.url
      Write-Host "    * $($item.name)"
      $detailHtml = $null
      try { $detailHtml = Get-Win1251Html $item.url } catch { Write-Warning "      detail fetch failed: $($_.Exception.Message)" }

      $desc = ""; $specs = ""; $price = $item.price; $images = @()
      if ($detailHtml) {
        $d = Parse-Detail $detailHtml
        if ($d.description) { $desc = $d.description }
        if ($d.specs) { $specs = $d.specs }
        if ($d.price) { $price = $d.price }
        if ($d.images.Count -gt 0) { $images = $d.images }
      }
      if ($images.Count -eq 0 -and $item.image) { $images = @($item.image) }

      $localImage = $null
      if ($images.Count -gt 0) {
        $fallbackExt = [System.IO.Path]::GetExtension(([System.Uri]$images[0]).AbsolutePath)
        if (-not $fallbackExt) { $fallbackExt = ".jpg" }
        $relNoExt = "assets/img/catalog/$($cat.slug)/$($sub.slug)/$slug"
        $destNoExt = Join-Path $repoRoot $relNoExt
        $imgAbs = (New-Object System.Uri((New-Object System.Uri($listUrl)), $images[0])).AbsoluteUri
        $written = Download-Image $imgAbs $destNoExt $fallbackExt
        if ($written) {
          $localImage = "assets/img/catalog/$($cat.slug)/$($sub.slug)/" + (Split-Path $written -Leaf)
        }
      }

      $products += [ordered]@{
        slug        = $slug
        name        = $item.name
        price       = $price
        image       = $localImage
        description = $desc
        specs       = $specs
        sourceUrl   = $item.url
      }
    }

    $catNode.subcategories += [ordered]@{
      slug     = $sub.slug
      name     = $sub.name
      group    = $sub.group
      products = $products
    }
  }

  $catalog.categories += $catNode
}

$jsonPath = Join-Path $dataDir "catalog.json"
$catalog | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Host "Wrote $jsonPath"
