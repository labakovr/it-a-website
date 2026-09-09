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

  // Возможности Битрикс24: липкие вкладки-разделы со скролл-спаем
  const featureTabs = document.querySelector(".feature-tabs");
  if (featureTabs) {
    const scroller = featureTabs.querySelector(".feature-tabs__scroll");
    const tabs = [...featureTabs.querySelectorAll(".feature-tab")];
    const sentinel = document.querySelector(".feature-tabs-sentinel");
    const pageHeader = document.querySelector(".header");
    const headerH = () => (pageHeader ? pageHeader.offsetHeight : 84);
    const sections = tabs
      .map((t) => document.querySelector(t.getAttribute("href")))
      .filter(Boolean);

    const syncOffsets = () => {
      featureTabs.style.setProperty("--feat-tabs-top", headerH() + "px");
      document.documentElement.style.scrollPaddingTop =
        headerH() + featureTabs.offsetHeight + 12 + "px";
      featureTabs.classList.toggle(
        "is-scrollable",
        scroller.scrollWidth > scroller.clientWidth + 1
      );
    };
    syncOffsets();
    window.addEventListener("resize", syncOffsets);

    if (sentinel && "IntersectionObserver" in window) {
      new IntersectionObserver(
        ([entry]) => featureTabs.classList.toggle("is-stuck", !entry.isIntersecting),
        { rootMargin: `-${headerH() + 1}px 0px 0px 0px` }
      ).observe(sentinel);
    }

    let activeId = null;
    const setActive = (id) => {
      if (id === activeId) return;
      activeId = id;
      tabs.forEach((t) => {
        const on = t.getAttribute("href") === "#" + id;
        t.classList.toggle("is-active", on);
        if (on) {
          const left = t.offsetLeft - scroller.clientWidth / 2 + t.clientWidth / 2;
          scroller.scrollTo({ left: Math.max(0, left), behavior: "smooth" });
        }
      });
    };

    let ticking = false;
    const spy = () => {
      ticking = false;
      const line = headerH() + featureTabs.offsetHeight + 16;
      let current = sections[0];
      sections.forEach((sec) => {
        if (sec.getBoundingClientRect().top <= line) current = sec;
      });
      if (current) setActive(current.id);
    };
    window.addEventListener("scroll", () => {
      if (!ticking) {
        ticking = true;
        requestAnimationFrame(spy);
      }
    });
    spy();

    tabs.forEach((t) => {
      t.addEventListener("click", () => setActive(t.getAttribute("href").slice(1)));
    });
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
