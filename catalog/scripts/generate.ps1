<#
  Renders static HTML pages for the equipment catalog from
  catalog/data/catalog.json, in the main site's own design system
  (header/footer/CSS classes copied from the rest of it-a.by).

  Produces:
    catalog/index.html
    catalog/<category>/index.html
    catalog/<category>/<subcategory>/index.html
    catalog/<category>/<subcategory>/<product>.html

  Run from repo root:  powershell -File catalog/scripts/generate.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
$jsonPath = Join-Path $repoRoot "catalog/data/catalog.json"
$data = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$siteUrl = "https://it-a.by"

function Localize($html, $root) {
  return [regex]::Replace($html, '(href|src)="(?!https?:|mailto:|tel:|#)([^"]*)"', "`$1=`"$root`$2`"")
}

function Strip-Tags($html) {
  if (-not $html) { return "" }
  $t = $html -replace '<[^>]+>', ' '
  $t = $t -replace '&nbsp;', ' '
  $t = $t -replace '&amp;', '&'
  $t = $t -replace '&quot;', '"'
  $t = $t -replace '&#\d+;', ' '
  $t = $t -replace '\s+', ' '
  return $t.Trim()
}

function Html-Escape($s) {
  if (-not $s) { return "" }
  return ($s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

function Format-Price($price) {
  if (-not $price) { return $null }
  return ('{0:N0}' -f [int]$price) -replace ',', ' '
}

$header = @'
<header class="header">
  <div class="container header__inner">
    <a href="index.html" class="brand">
      <img src="assets/img/logo-mark.png" alt="АйТи Аналитикс" class="brand__mark">
      <span class="brand__name">АйТи Аналитикс</span>
    </a>
    <nav class="nav">
      <div class="nav-item">
        <span class="nav-item-row">
          <a href="bitrix24.html" class="nav-link">Битрикс24</a>
          <button type="button" class="nav-caret" aria-label="Показать услуги по Битрикс24" aria-expanded="false">▾</button>
        </span>
        <div class="dropdown">
          <a href="features.html">Возможности Битрикс24</a>
          <a href="licenses.html">Лицензии Битрикс24</a>
          <a href="bitrix24.html">Внедрение Битрикс24</a>
          <a href="bitrix24.html">Сопровождение Битрикс24</a>
          <a href="education.html">Обучение Битрикс24</a>
        </div>
      </div>
      <div class="nav-item">
        <span class="nav-item-row">
          <a href="telephony.html" class="nav-link">Телефония</a>
          <button type="button" class="nav-caret" aria-label="Показать услуги по телефонии" aria-expanded="false">▾</button>
        </span>
        <div class="dropdown">
          <a href="telephony.html">Внедрение IP-телефонии</a>
          <a href="telephony.html">Настройка АТС</a>
          <a href="telephony.html">Сопровождение телефонии</a>
          <a href="catalog/index.html" class="is-active">Каталог оборудования</a>
        </div>
      </div>
      <div class="nav-item">
        <span class="nav-item-row">
          <a href="ai.html" class="nav-link">ИИ-решения</a>
          <button type="button" class="nav-caret" aria-label="Показать ИИ-решения" aria-expanded="false">▾</button>
        </span>
        <div class="dropdown">
          <a href="ai.html">Внедрение ИИ-ассистентов</a>
          <a href="ai.html">Автоматизация процессов</a>
          <a href="ai.html">Обучение и сопровождение</a>
        </div>
      </div>
      <div class="nav-item">
        <span class="nav-item-row">
          <a href="portfolio.html" class="nav-link">Портфолио</a>
          <button type="button" class="nav-caret" aria-label="Показать разделы портфолио" aria-expanded="false">▾</button>
        </span>
        <div class="dropdown">
          <a href="cases.html">Кейсы</a>
          <a href="reviews.html">Отзывы</a>
          <a href="certificates.html">Сертификаты</a>
          <a href="about.html">О нас</a>
        </div>
      </div>
      <a href="news.html">Новости</a>
    </nav>
    <div class="header__actions">
      <a href="tel:+375445057799" class="header__phone">+375 (44) 505-77-99</a>
      <a href="contacts.html#form" class="btn btn--primary btn--sm">Заказать звонок</a>
      <button class="nav-toggle" aria-label="Меню">☰</button>
    </div>
  </div>
</header>
'@

$footer = @'
<footer class="footer">
  <div class="container">
    <div class="footer__top">
      <div>
        <a href="index.html" class="brand" style="margin-bottom:16px;">
          <img src="assets/img/logo-mark.png" alt="АйТи Аналитикс" class="brand__mark">
          <span class="brand__name">АйТи Аналитикс</span>
        </a>
        <p>Внедрение Битрикс24 и систем телефонии. Ваш партнёр в мире Битрикс24 с 2011 года.</p>
      </div>
      <div>
        <h4>Навигация</h4>
        <ul>
          <li><a href="bitrix24.html">Битрикс24</a></li>
          <li><a href="telephony.html">Телефония</a></li>
          <li><a href="ai.html">ИИ-решения</a></li>
          <li><a href="portfolio.html">Портфолио</a></li>
          <li><a href="news.html">Новости</a></li>
          <li><a href="partners.html">Партнёрам</a></li>
          <li><a href="contacts.html">Контакты</a></li>
        </ul>
      </div>
      <div>
        <h4>Контакты</h4>
        <ul>
          <li><a href="tel:+375445057799">+375 (44) 505-77-99</a></li>
          <li><a href="mailto:sales@it-a.by">sales@it-a.by</a></li>
          <li><a href="contacts.html#map">г. Минск, ул. Лукьяновича, 10к7</a></li>
        </ul>
      </div>
      <div>
        <h4>Мы на связи</h4>
        <div class="social-row">
          <a href="https://www.instagram.com/it_a.by/" aria-label="Instagram" target="_blank" rel="noopener"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line></svg></a>
          <a href="https://t.me/ita_by_bitrix" aria-label="Telegram" target="_blank" rel="noopener"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg></a>
        </div>
      </div>
    </div>
    <div class="footer__bottom">
      <span>© 2011–2026 АйТи Аналитикс. УНП 791048093</span>
      <span>Все услуги: Битрикс24 · IP-телефония · Интеграции</span>
      <span><a href="assets/docs/privacy-policy.pdf" target="_blank" rel="noopener">Политика конфиденциальности</a></span>
    </div>
  </div>
</footer>

<script src="js/main.js"></script>
<script>
        (function(w,d,u){
                var s=d.createElement('script');s.async=true;s.src=u+'?'+(Date.now()/60000|0);
                var h=d.getElementsByTagName('script')[0];h.parentNode.insertBefore(s,h);
        })(window,document,'https://cdn-ru.bitrix24.by/b1536661/crm/site_button/loader_31_u35a1q.js');
</script>
'@

function Build-Page($title, $description, $urlPath, $jsonLdBlocks, $bodyHtml, $depth) {
  $root = "../" * $depth
  $canonical = "$siteUrl/$urlPath"
  $jsonLdHtml = ($jsonLdBlocks | ForEach-Object { "<script type=`"application/ld+json`">`n$_`n</script>" }) -join "`n"
  $head = @"
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$(Html-Escape $title)</title>
<meta name="description" content="$(Html-Escape $description)">
<link rel="canonical" href="$canonical">
<meta property="og:type" content="website">
<meta property="og:locale" content="ru_RU">
<meta property="og:site_name" content="АйТи Аналитикс">
<meta property="og:title" content="$(Html-Escape $title)">
<meta property="og:description" content="$(Html-Escape $description)">
<meta property="og:url" content="$canonical">
<meta property="og:image" content="$siteUrl/assets/img/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$(Html-Escape $title)">
<meta name="twitter:description" content="$(Html-Escape $description)">
<meta name="twitter:image" content="$siteUrl/assets/img/og-image.png">
<meta name="theme-color" content="#1d1d1b">
<link rel="icon" href="assets/img/logo-mark.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="css/style.css">
$jsonLdHtml
</head>
<body>

$header
<main>

$bodyHtml

</main>
$footer
</body>
</html>
"@
  return Localize $head $root
}

function Breadcrumb($crumbs) {
  # $crumbs: array of @{name=...; url=...}  (last one has no url -> current page)
  $parts = @()
  foreach ($c in $crumbs) {
    if ($c.url) {
      $parts += "<a href=`"$($c.url)`">$(Html-Escape $c.name)</a><span class=`"sep`">/</span>"
    } else {
      $parts += "<span>$(Html-Escape $c.name)</span>"
    }
  }
  return "<div class=`"breadcrumb`">$($parts -join '')</div>"
}

function BreadcrumbJsonLd($crumbs) {
  $items = @()
  $pos = 1
  foreach ($c in $crumbs) {
    $url = if ($c.url) { "$siteUrl/$($c.url)" } else { "$siteUrl/$($c.selfUrl)" }
    $items += [ordered]@{ "@type" = "ListItem"; position = $pos; name = $c.name; item = $url }
    $pos++
  }
  $ld = [ordered]@{ "@context" = "https://schema.org"; "@type" = "BreadcrumbList"; itemListElement = $items }
  return ($ld | ConvertTo-Json -Depth 6)
}

# Find a representative product image within a subcategory / category node
function Find-CoverImage($node) {
  if ($node.products) {
    foreach ($p in $node.products) { if ($p.image) { return $p.image } }
  }
  if ($node.subcategories) {
    foreach ($s in $node.subcategories) {
      $img = Find-CoverImage $s
      if ($img) { return $img }
    }
  }
  return $null
}

function Count-Products($node) {
  $n = 0
  if ($node.products) { $n += $node.products.Count }
  if ($node.subcategories) { foreach ($s in $node.subcategories) { $n += Count-Products $s } }
  return $n
}

$outRoot = Join-Path $repoRoot "catalog"
$sitemapUrls = New-Object System.Collections.Generic.List[object]
function Add-SitemapUrl($path, $changefreq, $priority) {
  $sitemapUrls.Add([ordered]@{ loc = "$siteUrl/$path"; changefreq = $changefreq; priority = $priority })
}

# ---------------------------------------------------------------------
# 1. Top catalog landing page: catalog/index.html
# ---------------------------------------------------------------------
$catTiles = ""
foreach ($cat in $data.categories) {
  $cover = Find-CoverImage $cat
  $count = Count-Products $cat
  $imgHtml = if ($cover) { "<img src=`"$cover`" alt=`"$(Html-Escape $cat.name)`" loading=`"lazy`">" } else { "" }
  $catTiles += @"
      <a href="catalog/$($cat.slug)/index.html" class="catalog-tile reveal">
        <div class="catalog-tile__img">$imgHtml</div>
        <div class="catalog-tile__body">
          <div class="catalog-tile__title">$(Html-Escape $cat.name)</div>
          <div class="catalog-tile__count">$count $(if ($count -eq 1) {"позиция"} elseif ($count -ge 2 -and $count -le 4) {"позиции"} else {"позиций"})</div>
        </div>
      </a>
"@
}

$crumbs = @(
  @{ name = "Главная"; url = "index.html" }
  @{ name = "Телефония"; url = "telephony.html" }
  @{ name = "Каталог оборудования"; url = $null; selfUrl = "catalog/index.html" }
)
$breadcrumbHtml = Breadcrumb $crumbs
$breadcrumbLd = BreadcrumbJsonLd $crumbs

$body = @"
<section class="page-hero">
  <div class="container page-hero__inner">
    $breadcrumbHtml
    <h1>Каталог оборудования для IP-телефонии</h1>
    <p class="hero__lead">Оборудование, которое мы поставляем и настраиваем при внедрении IP-телефонии и Битрикс24 — от настольных IP-телефонов и АТС Yeastar до гарнитур и VoIP-шлюзов. Актуальные цены и характеристики от поставщика IPmatika.</p>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="catalog-grid">
$catTiles
    </div>
    <p class="pricing-source" style="margin-top:32px;">Цены указаны в белорусских рублях и могут отличаться от актуальных — уточняйте наличие и стоимость у менеджера. Каталог обновляется автоматически по данным поставщика.</p>
  </div>
</section>
"@

$html = Build-Page "Каталог оборудования для IP-телефонии | АйТи Аналитикс" `
  "Каталог IP-телефонов, IP-АТС, VoIP-шлюзов и гарнитур, которые поставляет и настраивает АйТи Аналитикс. Актуальные цены и характеристики." `
  "catalog/index.html" @($breadcrumbLd) $body 1

New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
[System.IO.File]::WriteAllText((Join-Path $outRoot "index.html"), $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote catalog/index.html"
Add-SitemapUrl "catalog/index.html" "weekly" "0.6"

# ---------------------------------------------------------------------
# 2. Category pages: catalog/<cat>/index.html
# ---------------------------------------------------------------------
foreach ($cat in $data.categories) {
  $catDir = Join-Path $outRoot $cat.slug
  New-Item -ItemType Directory -Force -Path $catDir | Out-Null

  # group subcategories by their "group" label (if any) for a nicer layout
  $groups = [ordered]@{}
  foreach ($sub in $cat.subcategories) {
    $g = if ($sub.group) { $sub.group } else { "" }
    if (-not $groups.Contains($g)) { $groups[$g] = @() }
    $groups[$g] += $sub
  }

  $groupsHtml = ""
  foreach ($g in $groups.Keys) {
    $tiles = ""
    foreach ($sub in $groups[$g]) {
      $cover = Find-CoverImage $sub
      $count = $sub.products.Count
      $imgHtml = if ($cover) { "<img src=`"$cover`" alt=`"$(Html-Escape $sub.name)`" loading=`"lazy`">" } else { "" }
      $tiles += @"
        <a href="catalog/$($cat.slug)/$($sub.slug)/index.html" class="catalog-tile reveal">
          <div class="catalog-tile__img">$imgHtml</div>
          <div class="catalog-tile__body">
            <div class="catalog-tile__title">$(Html-Escape $sub.name)</div>
            <div class="catalog-tile__count">$count $(if ($count -eq 1) {"позиция"} elseif ($count -ge 2 -and $count -le 4) {"позиции"} else {"позиций"})</div>
          </div>
        </a>
"@
    }
    $groupTitle = if ($g) { "<div class=`"catalog-group-title`">$(Html-Escape $g)</div>" } else { "" }
    $groupsHtml += @"
    <div class="catalog-group">
      $groupTitle
      <div class="catalog-grid">
$tiles
      </div>
    </div>
"@
  }

  $crumbs = @(
    @{ name = "Главная"; url = "index.html" }
    @{ name = "Телефония"; url = "telephony.html" }
    @{ name = "Каталог оборудования"; url = "catalog/index.html" }
    @{ name = $cat.name; url = $null; selfUrl = "catalog/$($cat.slug)/index.html" }
  )
  $breadcrumbHtml = Breadcrumb $crumbs
  $breadcrumbLd = BreadcrumbJsonLd $crumbs

  $body = @"
<section class="page-hero">
  <div class="container page-hero__inner">
    $breadcrumbHtml
    <h1>$(Html-Escape $cat.name)</h1>
    <p class="hero__lead">Модели, которые мы поставляем и подключаем в рамках внедрения телефонии. Выберите раздел, чтобы посмотреть цены и характеристики.</p>
  </div>
</section>

<section class="section">
  <div class="container">
$groupsHtml
  </div>
</section>
"@

  $html = Build-Page "$($cat.name) — каталог оборудования | АйТи Аналитикс" `
    "$($cat.name): модели, цены и характеристики. Оборудование для IP-телефонии, которое поставляет и настраивает АйТи Аналитикс." `
    "catalog/$($cat.slug)/index.html" @($breadcrumbLd) $body 2

  [System.IO.File]::WriteAllText((Join-Path $catDir "index.html"), $html, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "Wrote catalog/$($cat.slug)/index.html"
  Add-SitemapUrl "catalog/$($cat.slug)/index.html" "weekly" "0.5"

  # -------------------------------------------------------------------
  # 3. Subcategory pages: catalog/<cat>/<sub>/index.html
  # -------------------------------------------------------------------
  foreach ($sub in $cat.subcategories) {
    $subDir = Join-Path $catDir $sub.slug
    New-Item -ItemType Directory -Force -Path $subDir | Out-Null

    $cardsHtml = ""
    foreach ($p in $sub.products) {
      $imgHtml = if ($p.image) { "<img src=`"$($p.image)`" alt=`"$(Html-Escape $p.name)`" loading=`"lazy`">" } else { "" }
      $priceHtml = if ($p.price) { "<div class=`"product-card__price`">$(Format-Price $p.price) BYN</div>" } else { "<div class=`"product-card__price--none`">Цена по запросу</div>" }
      $cardsHtml += @"
        <a href="catalog/$($cat.slug)/$($sub.slug)/$($p.slug).html" class="product-card reveal">
          <div class="product-card__img">$imgHtml</div>
          <div class="product-card__body">
            <div class="product-card__name">$(Html-Escape $p.name)</div>
            $priceHtml
          </div>
        </a>
"@
    }

    $crumbs = @(
      @{ name = "Главная"; url = "index.html" }
      @{ name = "Телефония"; url = "telephony.html" }
      @{ name = "Каталог оборудования"; url = "catalog/index.html" }
      @{ name = $cat.name; url = "catalog/$($cat.slug)/index.html" }
      @{ name = $sub.name; url = $null; selfUrl = "catalog/$($cat.slug)/$($sub.slug)/index.html" }
    )
    $breadcrumbHtml = Breadcrumb $crumbs
    $breadcrumbLd = BreadcrumbJsonLd $crumbs

    $body = @"
<section class="section pricing-section">
  <div class="container">
    <div class="page-intro-light reveal">
      $breadcrumbHtml
    </div>
    <div class="section-head reveal">
      <h1>$(Html-Escape $sub.name)</h1>
    </div>
    <div class="product-grid">
$cardsHtml
    </div>
  </div>
</section>
"@

    $html = Build-Page "$($sub.name) — каталог оборудования | АйТи Аналитикс" `
      "$($sub.name): модели, цены и характеристики. Оборудование для IP-телефонии, которое поставляет и настраивает АйТи Аналитикс." `
      "catalog/$($cat.slug)/$($sub.slug)/index.html" @($breadcrumbLd) $body 3

    [System.IO.File]::WriteAllText((Join-Path $subDir "index.html"), $html, (New-Object System.Text.UTF8Encoding($false)))
    Add-SitemapUrl "catalog/$($cat.slug)/$($sub.slug)/index.html" "weekly" "0.4"

    # -----------------------------------------------------------------
    # 4. Product pages
    # -----------------------------------------------------------------
    foreach ($p in $sub.products) {
      $crumbsP = @(
        @{ name = "Главная"; url = "index.html" }
        @{ name = "Телефония"; url = "telephony.html" }
        @{ name = "Каталог оборудования"; url = "catalog/index.html" }
        @{ name = $cat.name; url = "catalog/$($cat.slug)/index.html" }
        @{ name = $sub.name; url = "catalog/$($cat.slug)/$($sub.slug)/index.html" }
        @{ name = $p.name; url = $null; selfUrl = "catalog/$($cat.slug)/$($sub.slug)/$($p.slug).html" }
      )
      $breadcrumbHtmlP = Breadcrumb $crumbsP
      $breadcrumbLdP = BreadcrumbJsonLd $crumbsP

      $imgHtml = if ($p.image) { "<img src=`"$($p.image)`" alt=`"$(Html-Escape $p.name)`">" } else { "" }
      $priceHtml = if ($p.price) { "<div class=`"product-detail__price`">$(Format-Price $p.price) BYN</div>" } else { "<div class=`"product-detail__price--none`">Цена по запросу</div>" }

      $descHtml = if ($p.description) { "<div class=`"product-description`">$($p.description)</div>" } else { "" }
      $specsHtml = if ($p.specs) { "<div class=`"product-specs`"><h2>Характеристики</h2>$($p.specs)</div>" } else { "" }

      $jsonLdBlocks = @($breadcrumbLdP)
      $productLd = [ordered]@{
        "@context" = "https://schema.org"
        "@type" = "Product"
        name = $p.name
        image = if ($p.image) { "$siteUrl/$($p.image)" } else { $null }
        description = (Strip-Tags $p.description)
      }
      if ($p.price) {
        $productLd.offers = [ordered]@{
          "@type" = "Offer"
          price = "$($p.price)"
          priceCurrency = "BYN"
          availability = "https://schema.org/InStock"
          url = "$siteUrl/catalog/$($cat.slug)/$($sub.slug)/$($p.slug).html"
          seller = [ordered]@{ "@type" = "Organization"; name = "АйТи Аналитикс" }
        }
      }
      $jsonLdBlocks += ($productLd | ConvertTo-Json -Depth 6)

      $body = @"
<section class="section pricing-section">
  <div class="container">
    <div class="page-intro-light reveal">
      $breadcrumbHtmlP
    </div>
    <div class="product-detail reveal">
      <div class="product-detail__img">$imgHtml</div>
      <div>
        <h1>$(Html-Escape $p.name)</h1>
        $priceHtml
        <p class="product-detail__note">Цена носит информационный характер — актуальную стоимость и наличие уточняйте у менеджера.</p>
        <div class="hero__actions">
          <a href="contacts.html#form" class="btn btn--primary">Уточнить наличие и цену</a>
        </div>
        $descHtml
        $specsHtml
      </div>
    </div>
  </div>
</section>
"@

      $titleP = "$($p.name) — цена и характеристики | АйТи Аналитикс"
      $descP = "$($p.name): характеристики и цена в бел. руб. Поставляем и подключаем оборудование для IP-телефонии. АйТи Аналитикс, Минск."

      $htmlP = Build-Page $titleP $descP `
        "catalog/$($cat.slug)/$($sub.slug)/$($p.slug).html" $jsonLdBlocks $body 3

      [System.IO.File]::WriteAllText((Join-Path $subDir "$($p.slug).html"), $htmlP, (New-Object System.Text.UTF8Encoding($false)))
      Add-SitemapUrl "catalog/$($cat.slug)/$($sub.slug)/$($p.slug).html" "weekly" "0.3"
    }
  }
}

$sitemapEntries = ($sitemapUrls | ForEach-Object {
"  <url>
    <loc>$($_.loc)</loc>
    <changefreq>$($_.changefreq)</changefreq>
    <priority>$($_.priority)</priority>
  </url>"
}) -join "`n"
$sitemapXml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n$sitemapEntries`n</urlset>`n"
[System.IO.File]::WriteAllText((Join-Path $repoRoot "sitemap-catalog.xml"), $sitemapXml, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote sitemap-catalog.xml ($($sitemapUrls.Count) URLs)"

Write-Host "Catalog generation complete."
