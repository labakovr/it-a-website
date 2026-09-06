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
