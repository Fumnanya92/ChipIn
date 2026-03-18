/* ──────────────────────────────────────────────────────────────────────────────
   ChipIn Landing Page - Interactive Features
   (Tailwind CSS handles all visual styling)
   ────────────────────────────────────────────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  // Smooth scroll for all anchor links
  setupSmoothScroll();
  
  // Sticky navbar shadow effect
  setupStickyNavbar();
});

/* ──────────────────────────────────────────────────────────────────────────────
   Smooth Scroll for Navigation Links
   ────────────────────────────────────────────────────────────────────────────── */

function setupSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      const href = anchor.getAttribute('href');
      if (href === '#') return;
      
      e.preventDefault();
      const target = document.querySelector(href);
      
      if (target) {
        const offset = 80; // Account for sticky navbar
        const targetPosition = target.offsetTop - offset;
        
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
      }
    });
  });
}

/* ──────────────────────────────────────────────────────────────────────────────
   Sticky Navigation with Scroll Shadow Effect
   ────────────────────────────────────────────────────────────────────────────── */

function setupStickyNavbar() {
  const navbar = document.querySelector('[data-purpose="navigation-bar"]');
  
  if (!navbar) return;
  
  window.addEventListener('scroll', () => {
    if (window.scrollY > 10) {
      // Add shadow when scrolled
      navbar.style.boxShadow = '0 10px 30px rgba(17, 180, 212, 0.15)';
    } else {
      // Remove shadow at top
      navbar.style.boxShadow = 'none';
    }
  });
}
