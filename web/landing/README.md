# ChipIn Landing Page

A professional, responsive landing page for the ChipIn cost-sharing platform. Built with static HTML, CSS, and JavaScript.

## 📁 Files

- **index.html** — Main landing page with semantic markup
- **styles.css** — Responsive styling (mobile-first, professional design)
- **scripts.js** — JavaScript interactivity (mobile menu, FAQ, smooth scroll, animations)

## 🎯 Sections

1. **Navigation** — Sticky header with logo, menu, and CTA
2. **Hero** — Headline, subheadline, trust badges, phone mockup, download CTAs
3. **Features** — 6 key features with icons (hover effects, cards)
4. **How It Works** — 4-step process visualization with icons
5. **Testimonials** — 3 user reviews with ratings and avatars
6. **About** — Mission statement, company stats with counting animation
7. **FAQ** — 6 common questions with accordion toggle
8. **Download CTA** — Prominent call-to-action with App Store/Play Store links
9. **Footer** — Navigation links, social media, legal

## 🎨 Design Features

### Colors
- **Primary:** #1F40AF (Professional blue)
- **Secondary:** #00D084 (Fresh green)
- **Accent:** #FFB84D (Warm orange)
- **Neutral palette:** 9 shades for backgrounds, text, borders

### Typography
- **Font:** Inter (modern, professional)
- **Weights:** 300–800 for strong hierarchy

### Responsive Design
- **Desktop:** Full multi-column layouts
- **Tablet:** Optimized grid adjustments
- **Mobile:** Single column, touch-friendly buttons, hidden hero visual

### Interactive Elements
- Mobile hamburger menu ☰
- FAQ accordion with smooth toggle
- Fade-in animations on scroll (Intersection Observer)
- Counter animations for statistics
- Smooth scroll navigation
- Sticky navbar with shadow on scroll
- Hover effects on buttons and cards

## 🚀 How to Use

### Local Development

1. Open `index.html` in your browser:
   ```bash
   open web/landing/index.html
   ```

2. Or start a local server:
   ```bash
   cd web/landing
   python -m http.server 8000
   # Then visit http://localhost:8000
   ```

### Deployment

The landing page is static and can be deployed to:
- **GitHub Pages** — Upload `/web/landing/` to your repo
- **Vercel** — Connect repo, set root to `web/landing/`
- **Netlify** — Drag & drop folder or connect GitHub
- **Firebase Hosting** — Deploy with `firebase deploy`


### Update Content

Edit `index.html` to:
- Change app store links (search for `play.google.com` and `apps.apple.com`)
- Update testimonials with real user reviews
- Modify feature descriptions
- Add video demo (replace video src in "How It Works")
- Update social media links in footer

Edit `styles.css` to:
- Adjust color palette (update CSS variables at top)
- Modify spacing or fonts
- Change breakpoints for responsive design

## 📊 Performance

- **No framework overhead** — Pure HTML/CSS/JS
- **Lightweight** — <50KB total (uncompressed)
- **Fast load times** — Optimized for Core Web Vitals
- **SEO-ready** — Semantic HTML, meta tags, structured content

## 🔗 Links to Update

Search and replace in `index.html`:
- `https://play.google.com/store/apps/details?id=com.chipin` → Your actual Play Store link
- `https://apps.apple.com/app/chipin` → Your actual App Store link
- `https://twitter.com/chipin` → Your Twitter handle
- `https://instagram.com/chipin` → Your Instagram handle
- `https://linkedin.com/company/chipin` → Your LinkedIn company page
- `/privacy` → Your privacy policy URL
- `/terms` → Your terms of service URL
- `/demo.mp4` → Your demo video URL

## 🛠️ Browser Support

- **Chrome** 88+
- **Firefox** 85+
- **Safari** 14+
- **Edge** 88+
- **Mobile browsers** (iOS Safari, Chrome Mobile)

## 📝 Customization Guide

### Update Hero Phone Mockup
Modify the screen content in the `.screen-content` div to match your app's actual UI.

### Add Your Logo
Replace the emoji 💰 in the `.logo` div with an image:
```html
<img src="logo.png" alt="ChipIn Logo" style="width: 32px; height: 32px;">
```

### Change Colors
Update CSS variables in `styles.css`:
```css
:root {
  --primary: #YOUR_COLOR;
  --secondary: #YOUR_COLOR;
  /* ... etc */
}
```

### Add Analytics
Add Google Analytics or Mixpanel tracking code in `<head>`:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
```

## 📱 Mobile Optimization

- Touch-friendly buttons (min 48px height)
- Readable text (16px+ on mobile)
- Optimized spacing for small screens
- Hidden elements that don't fit (hero visual on mobile)
- Hamburger menu for navigation

## ⚡ Quick Start Checklist

- [ ] Replace app store links
- [ ] Update testimonials with real reviews
- [ ] Add your demo video
- [ ] Update social media links
- [ ] Customize colors if needed
- [ ] Add logo image
- [ ] Test on mobile devices
- [ ] Deploy to hosting
- [ ] Share with team & stakeholders

## 📞 Support

For questions or customizations, refer to the inline comments in:
- `styles.css` — Each section is clearly labeled
- `scripts.js` — Functions are documented

---

**Built by Sam Agent** | ChipIn Landing Page v1.0
