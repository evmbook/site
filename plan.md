# Plan: Sci-Fi Mountain Landscape Background Redesign

## Inspiration Analysis

The reference image features:
- **Large red/coral moon** rising at horizon level, emitting soft glow
- **Mountain silhouettes** in layers (parallax depth effect)
- **Road/path** leading toward the moon (vanishing point perspective)
- **Color palette**: Deep teals, dark cyans, coral/salmon reds, subtle purples
- **Atmosphere**: Moody, contemplative, vast scale
- **Light sources**: Moon glow reflecting on wet road surface

## New Color Palette

### Primary Colors (derived from image)
```css
/* Moon and warm accents */
--moon-coral: #E85A5A          /* Main moon color */
--moon-glow: #FF7B7B           /* Moon outer glow */
--moon-core: #FFB4B4           /* Moon bright center */

/* Sky and atmosphere */
--sky-deep: #0A1419            /* Deepest sky (top) */
--sky-mid: #0F1E24             /* Mid sky */
--sky-horizon: #1A2830         /* Horizon sky */

/* Mountains (layered silhouettes) */
--mountain-far: #152028        /* Distant mountains */
--mountain-mid: #0D1518        /* Middle layer */
--mountain-near: #080D0F       /* Foreground/closest */

/* Road and reflections */
--road-surface: #0C1215        /* Asphalt base */
--road-reflection: rgba(232, 90, 90, 0.15)  /* Moon reflection */
--road-line: rgba(232, 90, 90, 0.4)         /* Center line glow */

/* Accent colors (keeping some for UI) */
--accent-cyan: #00D4D4         /* Subtle cyan for links */
--accent-teal: #2DD4BF         /* Secondary accent */
--text-primary: #E8E4E0        /* Warm white text */
--text-secondary: #A8B4BC      /* Muted blue-gray */
--text-muted: #5E6B73          /* Very muted */
```

### Semantic Mappings
```css
/* Chain colors - adapted to new palette */
--etc-color: #2DD4BF           /* Teal for ETC */
--eth-color: #E85A5A           /* Coral for ETH */
--evm-color: #00D4D4           /* Cyan for EVM */
```

## BackgroundSystem Redesign

### Layer Structure (bottom to top)

1. **Sky Gradient Base** (z-0)
   - Three-stop vertical gradient: `--sky-deep` → `--sky-mid` → `--sky-horizon`
   - Creates the night sky backdrop

2. **Stars Layer** (z-1)
   - Subtle scattered dots using radial gradients
   - Very low opacity, no animation (static stars)
   - Concentrated more at top of screen

3. **Moon** (z-2)
   - Large radial gradient positioned at ~50% horizontal, ~45% vertical
   - Multiple layers: core glow, main body, outer atmosphere
   - Size: ~300-400px diameter
   - Subtle breathing animation (very slow, 20s cycle)

4. **Distant Mountains** (z-3)
   - SVG path or CSS clip-path creating jagged mountain silhouette
   - Color: `--mountain-far`
   - Positioned at ~40% from bottom
   - Subtle parallax on scroll (optional)

5. **Mid Mountains** (z-4)
   - Larger, more defined peaks
   - Color: `--mountain-mid`
   - Positioned at ~30% from bottom
   - Slightly darker than distant

6. **Near Mountains/Hills** (z-5)
   - Closest layer, most defined
   - Color: `--mountain-near`
   - Positioned at ~20% from bottom

7. **Road Surface** (z-6)
   - Perspective trapezoid shape narrowing toward horizon
   - Base color with subtle noise texture
   - Center line with glow effect

8. **Moon Reflection on Road** (z-7)
   - Vertical gradient streak on road surface
   - Animated shimmer effect (subtle)

9. **Atmospheric Haze** (z-8)
   - Horizontal gradient adding depth/fog between layers
   - Very subtle, positioned near horizon

10. **Vignette** (z-9)
    - Radial gradient darkening edges
    - Focus attention toward center/moon

### Removed Elements
- Orbiting planets/rings
- Neural network lanes
- Processing hubs
- Dot lattice pattern
- Diamond grid
- Scan shimmer

### Simplified Animations
- Moon: Very subtle scale breathing (0.98-1.02, 20s)
- Road reflection: Gentle vertical shimmer (15s)
- Stars: Optional subtle twinkle (30s, opacity only)

## CSS Changes in globals.css

### Update CSS Variables
Replace the neon palette with the new mountain landscape palette.

### Update Utility Classes
- Remove `.glow-green`, `.glow-pink` etc.
- Add `.glow-coral`, `.glow-teal`, `.glow-cyan`
- Update gradients to use new colors

### Update Prose Styling
- Keep the reading-panel structure
- Update accent colors in callouts/code blocks
- Maintain high contrast for readability

## Component Updates

### BackgroundSystem.tsx - Complete Rewrite
New component structure:
```tsx
export function BackgroundSystem() {
  return (
    <div className="fixed inset-0 -z-10 overflow-hidden">
      {/* Sky gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#0A1419] via-[#0F1E24] to-[#1A2830]" />

      {/* Stars */}
      <Stars />

      {/* Moon with glow */}
      <Moon />

      {/* Mountain layers */}
      <MountainLayer variant="far" />
      <MountainLayer variant="mid" />
      <MountainLayer variant="near" />

      {/* Road with reflection */}
      <Road />

      {/* Atmospheric effects */}
      <Atmosphere />

      {/* Vignette */}
      <Vignette />
    </div>
  )
}
```

### Button.tsx
- Update hover/active colors to use new accent palette
- Keep minimal styling approach

### Header.tsx, Sidebar.tsx
- Update accent colors for consistency
- Links: cyan on hover
- Active states: coral/teal accents

## Implementation Order

1. **Update globals.css**
   - Replace color palette CSS variables
   - Update utility classes
   - Update prose styling accents

2. **Rewrite BackgroundSystem.tsx**
   - Create mountain silhouette SVG paths
   - Implement new layered structure
   - Add subtle animations

3. **Update UI components**
   - Button.tsx accent colors
   - Header.tsx styling
   - Sidebar.tsx styling
   - ChapterNav.tsx styling

4. **Test and refine**
   - Check readability with new background
   - Adjust reading-panel if needed
   - Verify mobile responsiveness

5. **Build and deploy**

## Mountain SVG Paths

Pre-defined paths for each mountain layer:

```tsx
// Far mountains - gentle rolling peaks
const farMountains = "M0,100 L0,65 Q15,55 30,60 Q50,45 70,55 Q90,40 110,50 Q130,35 150,45 Q170,30 190,40 Q210,25 230,35 Q250,20 270,30 Q290,15 310,25 L350,20 L400,30 L400,100 Z"

// Mid mountains - more dramatic peaks
const midMountains = "M0,100 L0,70 L20,60 L40,72 L60,55 L80,65 L100,45 L120,58 L140,50 L160,62 L180,40 L200,55 L220,48 L240,60 L260,35 L280,50 L300,42 L320,55 L340,38 L360,52 L380,45 L400,55 L400,100 Z"

// Near mountains - sharp foreground silhouette
const nearMountains = "M0,100 L0,80 L30,75 L50,82 L70,70 L100,78 L120,65 L150,75 L170,68 L200,80 L220,72 L250,82 L270,75 L300,85 L320,78 L350,88 L380,82 L400,90 L400,100 Z"
```

## Success Criteria

- [ ] Background evokes sci-fi mountain landscape atmosphere
- [ ] Large coral/red moon is prominent but not overwhelming
- [ ] Mountain silhouettes create depth and layering
- [ ] Road element adds perspective and draws eye to moon
- [ ] Colors are cohesive across all UI elements
- [ ] Text remains highly readable against new background
- [ ] Animations are subtle and don't distract from content
- [ ] Mobile responsive (mountains scale appropriately)
- [ ] Reduced motion preference respected
