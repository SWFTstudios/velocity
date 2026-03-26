# Design System Specification: Midnight Calm Editorial

## 1. Overview & Creative North Star
**The Creative North Star: "The Luminescent Sanctuary"**

This design system rejects the clinical, high-glare standards of modern SaaS in favor of a bespoke, editorial experience optimized for the circadian rhythm. Our goal is to create a digital environment that feels like a high-end physical space—think of a dimly lit, private library where the only light comes from soft amber lamps. 

We break the "template" look through **Luminous Asymmetry**. By utilizing extreme typographic scales and shifting tonal surfaces, we guide the eye without the need for aggressive "look at me" colors. This system is inherently color-blind friendly because it relies on **Luminance Contrast** (the difference between light and dark) and **Geometric Weight** rather than hue-based signaling.

---

## 2. Color & Tonal Architecture
The palette is built on a foundation of `surface` (#11131c) and `primary` (#ffba38), creating a high-contrast yet low-strain experience.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections or cards. 
Structure must be achieved through:
- **Surface Shifts:** A `surface_container_low` section sitting on a `surface` background.
- **Negative Space:** Using the `12` (4rem) or `16` (5.5rem) spacing tokens to create mental boundaries.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of materials. Use the following tiers to define depth:
1.  **Base:** `surface_container_lowest` (#0c0e17) – Use for deep background regions.
2.  **Standard:** `surface` (#11131c) – The default canvas.
3.  **Elevated:** `surface_container` (#1d1f29) – For secondary content areas.
4.  **Accentuated:** `surface_container_highest` (#32343e) – For active or high-focus containers.

### The "Glass & Signature Texture" Rule
To add "soul" to the interface:
- **Glassmorphism:** For floating menus or navigation bars, use `surface_bright` at 60% opacity with a `backdrop-blur` of 20px. This allows the deep charcoals to bleed through, maintaining the "sleep-optimized" feel.
- **Luminous Gradients:** Main CTAs should not be flat. Use a subtle linear gradient from `primary` (#ffba38) to `on_primary_container` (#a87500) at a 135-degree angle to give the element weight and a soft glow.

---

## 3. Typography: The Lexend Scale
We use **Lexend** exclusively. Its hyper-legible, sans-serif construction was designed specifically to reduce visual stress and improve reading speed.

*   **Display (Editorial Impact):** Use `display-lg` (3.5rem) for hero moments. This should always be in `on_surface`. Use intentional asymmetry by left-aligning large display text against right-aligned body copy.
*   **Headlines (Wayfinding):** `headline-lg` (2rem) serves as the primary anchor for content sections.
*   **Body (Readability):** `body-lg` (1rem) is the default. Never go below `body-md` (0.875rem) for functional text to ensure accessibility for tired eyes.
*   **Labels:** Use `label-md` in `primary` (#ffba38) for uppercase overlines to categorize content without adding bulk.

---

## 4. Elevation & Depth
In this system, "Up" means "Brighter," not "Shadowier."

*   **The Layering Principle:** To lift a card, place a `surface_container_high` card on a `surface_dim` background. The eye perceives the lighter value as being closer to the viewer.
*   **Ambient Glows:** Traditional black shadows are forbidden. If an element must float (like a FAB), use a large, diffused shadow: `box-shadow: 0 20px 40px rgba(17, 19, 28, 0.4)`. The shadow color is a tinted version of the background.
*   **The Ghost Border Fallback:** For input fields where a boundary is legally or functionally required, use `outline_variant` (#46464b) at **20% opacity**. This creates a "suggestion" of a box rather than a hard cage.

---

## 5. Components

### Buttons
*   **Primary:** Gradient of `primary` to `on_primary_container`. Text: `on_primary_fixed` (Deep Charcoal). High luminosity makes this instantly recognizable to all vision types.
*   **Secondary:** `surface_container_highest` background with a `primary` "Ghost Border."
*   **Tertiary:** Text only in `secondary` (#bac3ff), utilizing a `full` (9999px) corner radius on hover states.

### Cards & Lists
*   **No Dividers:** Separate list items using `2` (0.7rem) of vertical padding and a subtle background toggle between `surface` and `surface_container_low`.
*   **Shape-Based States:** Use the `xl` (0.75rem) roundedness for standard cards. When a card is "Selected," increase its roundedness or add a `primary` glyph—do not rely on a color change alone.

### Input Fields
*   **The "Quiet" Input:** Use `surface_container_lowest` as the field background. The label (`body-sm`) should sit above the field in `on_tertiary_container`.
*   **Error States:** Use `error` (#ffb4ab) but accompany it with a specific "Warning" icon. The stroke weight of the icon should increase to 2px to ensure it is visually distinct through shape.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use extreme white space. If in doubt, double the padding using the `10` or `12` scale.
*   **Do** use `primary` (#ffba38) for all "Actionable" elements. It mimics the warmth of a candle and is the most visible "warm" color for color-blind users.
*   **Do** use `secondary` (muted indigo) for "Information Only" or "Passive" elements.

### Don't
*   **Don’t** use pure black (#000000) or pure white (#FFFFFF). It causes "halation" (glowing effect) on OLED screens which strains the eyes at night.
*   **Don’t** use 1px dividers. They create "visual noise" that breaks the sanctuary feel.
*   **Don’t** use motion that is faster than 300ms. Transitions should be "Eased-Out" and feel fluid, like ink moving through water.

### Accessibility Note
By prioritizing **Luminance Contrast** (keeping `primary` at a high light value and `surface` at a very low light value), we ensure WCAG AAA compliance for text legibility without needing "emergency" red or blue colors that disrupt sleep patterns.