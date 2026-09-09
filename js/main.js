document.addEventListener("DOMContentLoaded", () => {
  // Mobile nav toggle
  const header = document.querySelector(".header");
  const toggle = document.querySelector(".nav-toggle");
  if (toggle && header) {
    toggle.addEventListener("click", () => {
      header.classList.toggle("is-open");
      toggle.textContent = header.classList.contains("is-open") ? "✕" : "☰";
    });
    document.querySelectorAll(".nav a").forEach((link) => {
      link.addEventListener("click", () => {
        header.classList.remove("is-open");
        toggle.textContent = "☰";
      });
    });
  }

  // Nav dropdown submenus (tap-to-expand on mobile/tablet; desktop
  // uses plain CSS :hover, this only matters below the 1150px
  // breakpoint where the caret becomes visible)
  document.querySelectorAll(".nav-caret").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      const item = btn.closest(".nav-item");
      if (!item) return;
      const isOpen = item.classList.toggle("is-open");
      btn.setAttribute("aria-expanded", isOpen ? "true" : "false");
    });
  });

  // "Наши услуги" tabbed block
  const serviceTabs = document.querySelectorAll(".services-tab");
  const servicePanels = document.querySelectorAll(".services-panel");
  const servicesLink = document.querySelector("[data-services-link]");
  serviceTabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      serviceTabs.forEach((t) => {
        t.classList.remove("is-active");
        t.setAttribute("aria-selected", "false");
      });
      servicePanels.forEach((p) => p.classList.remove("is-active"));
      tab.classList.add("is-active");
      tab.setAttribute("aria-selected", "true");
      const panel = document.querySelector(`.services-panel[data-panel="${tab.dataset.tab}"]`);
      if (panel) panel.classList.add("is-active");
      if (servicesLink && tab.dataset.href) servicesLink.href = tab.dataset.href;
    });
  });

  // Возможности Битрикс24: закреплённая сцена — прокрутка листает разделы 01–12
  const featureScene = document.querySelector(".feature-scene");
  const featurePin = featureScene && featureScene.querySelector(".feature-scene__pin");
  const featureExplorer = document.querySelector(".feature-explorer");
  if (featureScene && featurePin && featureExplorer) {
    const fTabs = [...featureExplorer.querySelectorAll(".services-tab")];
    const fPanels = [...featureExplorer.querySelectorAll(".services-panel")];
    const fBar = featureExplorer.querySelector(".feature-progress__bar");
    const tabStrip = featureExplorer.querySelector(".services-tabs");
    const panelsWrap = featureExplorer.querySelector(".services-panels");
    const mqMobile = window.matchMedia("(max-width: 900px)");
    const mqReduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    const N = fTabs.length;
    const STEP_VH = 0.7; // доля высоты экрана на один раздел
    let stepPx = 0;
    let sceneTop = 0;
    let current = -1;
    let enabled = false;

    const pinTop = () => (mqMobile.matches ? 64 : 84);

    // Держим область панелей по высоте самой большой из них — чтобы блок
    // не «прыгал» при смене раздела и чтобы проверка «помещается ли сцена»
    // считалась по худшему случаю.
    function equalizePanels() {
      if (!panelsWrap) return 0;
      panelsWrap.style.minHeight = "";
      const w = panelsWrap.clientWidth;
      let max = 0;
      fPanels.forEach((p) => {
        const active = p.classList.contains("is-active");
        if (!active) {
          p.style.cssText = "display:block;position:absolute;visibility:hidden;left:0;right:0;width:" + w + "px";
        }
        max = Math.max(max, p.getBoundingClientRect().height);
        if (!active) p.style.cssText = "";
      });
      max = Math.ceil(max);
      panelsWrap.style.minHeight = max + "px";
      return max;
    }

    function setActive(idx, viaClick) {
      idx = Math.max(0, Math.min(N - 1, idx));
      if (idx === current) return;
      current = idx;
      fTabs.forEach((t, i) => {
        t.classList.toggle("is-active", i === idx);
        t.setAttribute("aria-selected", i === idx ? "true" : "false");
      });
      fPanels.forEach((p, i) => p.classList.toggle("is-active", i === idx));
      // «Все услуги →» на главной ведёт на страницу активного направления
      if (servicesLink && fTabs[idx].dataset.href) servicesLink.href = fTabs[idx].dataset.href;
      if (fBar) fBar.style.width = (N > 1 ? (idx / (N - 1)) * 100 : 0) + "%";
      if (tabStrip && mqMobile.matches) {
        const tab = fTabs[idx];
        const left = tab.offsetLeft - (tabStrip.clientWidth - tab.offsetWidth) / 2;
        tabStrip.scrollTo({ left: Math.max(0, left), behavior: viaClick ? "smooth" : "auto" });
      }
    }

    function measure() {
      // меряем высоту контента сцены при её же стилях (не в запасном режиме),
      // чтобы решить, помещается ли закреплённый блок в экран
      document.documentElement.classList.remove("no-feature-scene");
      featureScene.style.height = "";
      if (current < 0) setActive(0);
      equalizePanels();
      const box = featurePin.firstElementChild; // .container с контентом
      const pad = parseFloat(getComputedStyle(featurePin).paddingTop) +
        parseFloat(getComputedStyle(featurePin).paddingBottom);
      const natural = box.getBoundingClientRect().height + pad;
      const fits = natural <= window.innerHeight - pinTop() + 8;

      enabled = !mqReduce.matches && fits;
      document.documentElement.classList.toggle("no-feature-scene", !enabled);
      if (!enabled) {
        featureScene.style.height = "";
        return;
      }
      stepPx = Math.round(window.innerHeight * STEP_VH);
      featureScene.style.height = window.innerHeight + stepPx * (N - 1) + "px";
      sceneTop = featureScene.getBoundingClientRect().top + window.scrollY;
      update();
    }

    function update() {
      if (!enabled) return;
      // пересчитываем позицию сцены каждый раз — она может «уехать»,
      // если контент выше подгрузился (шрифт, изображения)
      sceneTop = featureScene.getBoundingClientRect().top + window.scrollY;
      const dist = window.scrollY - (sceneTop - pinTop());
      setActive(Math.round(dist / stepPx));
    }

    fTabs.forEach((tab, i) => {
      tab.addEventListener("click", (e) => {
        if (!enabled) return; // не мешаем обычному переключению вкладок
        e.preventDefault();
        window.scrollTo({ top: sceneTop - pinTop() + i * stepPx + 2, behavior: "smooth" });
        setActive(i, true);
      });
    });

    let ticking = false;
    window.addEventListener(
      "scroll",
      () => {
        if (ticking) return;
        ticking = true;
        requestAnimationFrame(() => {
          update();
          ticking = false;
        });
      },
      { passive: true }
    );

    let resizeTimer;
    window.addEventListener("resize", () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(measure, 150);
    });
    mqReduce.addEventListener("change", measure);
    window.addEventListener("load", measure); // пересчёт после подгрузки шрифта

    measure();
  }

  // News carousel arrows
  const newsTrack = document.querySelector(".news-track");
  const newsPrev = document.querySelector(".news-arrow--prev");
  const newsNext = document.querySelector(".news-arrow--next");
  if (newsTrack && newsPrev && newsNext) {
    const step = () => {
      const card = newsTrack.querySelector(".news-card");
      const gap = parseFloat(getComputedStyle(newsTrack).gap) || 22;
      return card ? card.offsetWidth + gap : 280;
    };
    newsPrev.addEventListener("click", () => {
      newsTrack.scrollBy({ left: -step(), behavior: "smooth" });
    });
    newsNext.addEventListener("click", () => {
      newsTrack.scrollBy({ left: step(), behavior: "smooth" });
    });
  }

  // Cases carousel arrows
  const casesTrack = document.querySelector(".cases-track");
  const casesPrev = document.querySelector(".cases-arrow--prev");
  const casesNext = document.querySelector(".cases-arrow--next");
  if (casesTrack && casesPrev && casesNext) {
    const caseStep = () => {
      const card = casesTrack.querySelector(".cases-card");
      const gap = parseFloat(getComputedStyle(casesTrack).gap) || 20;
      return card ? card.offsetWidth + gap : 300;
    };
    casesPrev.addEventListener("click", () => {
      casesTrack.scrollBy({ left: -caseStep(), behavior: "smooth" });
    });
    casesNext.addEventListener("click", () => {
      casesTrack.scrollBy({ left: caseStep(), behavior: "smooth" });
    });
  }

  // Тарифы Битрикс24: переключатель "Облако / Коробка"
  const pricingModeToggle = document.querySelector(".pricing-mode-toggle");
  if (pricingModeToggle) {
    const modeBtns = pricingModeToggle.querySelectorAll(".pricing-mode-toggle__btn");
    const modePanels = document.querySelectorAll(".pricing-mode-panel");
    modeBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        modeBtns.forEach((b) => b.classList.remove("is-active"));
        btn.classList.add("is-active");
        modePanels.forEach((panel) => {
          panel.hidden = panel.dataset.modePanel !== btn.dataset.mode;
        });
      });
    });
  }

  // Полное сравнение тарифов: переключатель "Показать различия" + сворачивание разделов
  const diffToggle = document.querySelector(".compare-diff-toggle");
  if (diffToggle) {
    const rows = document.querySelectorAll(".compare-table--full tbody tr");
    rows.forEach((row) => {
      const cells = [...row.querySelectorAll("td")].slice(1);
      const values = cells.map((c) => c.textContent.trim());
      const uniform = values.every((v) => v === values[0]);
      if (uniform) row.dataset.uniform = "true";
    });
    diffToggle.addEventListener("change", () => {
      document.body.classList.toggle("show-diff-only", diffToggle.checked);
    });
  }

  document.querySelectorAll(".compare-full-section__title").forEach((title) => {
    title.addEventListener("click", () => {
      const section = title.closest(".compare-full-section");
      if (section) section.classList.toggle("is-collapsed");
    });
  });

  // Тарифы Битрикс24: селектор количества пользователей (коробочная версия)
  document.querySelectorAll(".price-card__users-toggle").forEach((toggle) => {
    let prices = {};
    try {
      prices = JSON.parse(toggle.dataset.prices || "{}");
    } catch (e) {
      prices = {};
    }
    const card = toggle.closest(".price-card");
    const amountEl = card ? card.querySelector(".price-card__amount--users") : null;
    const countEl = card ? card.querySelector(".price-card__users-count") : null;
    const buttons = toggle.querySelectorAll(".price-card__users-btn");
    buttons.forEach((btn) => {
      btn.addEventListener("click", () => {
        buttons.forEach((b) => b.classList.remove("is-active"));
        btn.classList.add("is-active");
        const users = btn.dataset.users;
        if (amountEl && prices[users]) amountEl.textContent = prices[users] + " BYN";
        if (countEl) countEl.textContent = users;
      });
    });
  });

  // Тарифы Битрикс24: переключатель "на месяц / на год"
  const pricingToggle = document.querySelector(".pricing-toggle");
  const pricingGrid = document.querySelector(".pricing-grid");
  if (pricingToggle && pricingGrid) {
    const toggleBtns = pricingToggle.querySelectorAll(".pricing-toggle__btn");
    toggleBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        toggleBtns.forEach((b) => b.classList.remove("is-active"));
        btn.classList.add("is-active");
        pricingGrid.classList.toggle("is-yearly", btn.dataset.period === "year");
      });
    });
  }

  // Scroll reveal
  const revealEls = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && revealEls.length) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12 }
    );
    revealEls.forEach((el) => io.observe(el));
  } else {
    revealEls.forEach((el) => el.classList.add("is-visible"));
  }

  // Contact form (front-end only demo)
  const form = document.querySelector(".contact-form");
  if (form) {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const success = document.querySelector(".form-success");
      form.style.display = "none";
      if (success) success.style.display = "block";
    });
  }
});
