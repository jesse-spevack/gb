# GradeBook Design System

This document provides a comprehensive design system extracted from the Rails application's views and Tailwind usage. It serves as a reference for AI coding agents to create design-aligned views.

## Table of Contents
1. [Color System](#color-system)
2. [Typography Scale](#typography-scale)
3. [Spacing System](#spacing-system)
4. [Component Patterns](#component-patterns)
5. [Layout Patterns](#layout-patterns)
6. [Interactive States](#interactive-states)
7. [Responsive Patterns](#responsive-patterns)

---

## Color System

### Primary Colors
- **Blue (Primary Brand)**
  - `blue-600`: Main CTAs, primary buttons, active navigation (74 uses)
  - `blue-500`: Secondary actions, focus rings, progress bars (33 uses)
  - `blue-700`: Hover states on primary elements (19 uses)
  - `blue-100`: Light backgrounds for info states (12 uses)

### Neutral Colors
- **Gray (Foundation)**
  - `gray-900`: Primary headings, important text (67 uses - most used)
  - `gray-700`: Body text, secondary content (46 uses)
  - `gray-600`: Secondary text, muted labels (48 uses)
  - `gray-500`: Placeholder text, tertiary content (32 uses)
  - `gray-50`: Light backgrounds, hover states (28 uses)
  - `white`: Primary backgrounds, cards (33 uses)

### Semantic Colors
- **Success**: `green-600` text on `green-100` background
- **Warning**: `amber-600` text on `amber-100` background  
- **Error**: `red-600`/`red-700` text on `red-100` background

### Border & Ring Colors
- Default borders: `border-gray-200`, `border-gray-300`
- Focus rings: `ring-blue-500` with `ring-offset-2`
- Transparent borders: `border-transparent`

---

## Typography Scale

### Text Sizes (Most Common)
1. **`text-sm`** (104 uses) - UI text, buttons, navigation
2. **`text-base`** (28 uses) - Body paragraphs, main content
3. **`text-xs`** (20 uses) - Badges, metadata, helper text
4. **`text-lg` to `text-7xl`** - Headings and hero sections

### Font Weights
1. **`font-medium`** (68 uses) - Default UI text weight
2. **`font-semibold`** (61 uses) - Headings, emphasis
3. **`font-bold`** (6 uses) - Hero headlines, critical CTAs

### Common Typography Combinations
```erb
<!-- Standard UI Text -->
class="text-sm font-medium"

<!-- Section Heading -->
class="text-4xl font-semibold"

<!-- Small Label/Badge -->
class="text-xs font-medium"

<!-- Subheading -->
class="text-lg font-semibold"
```

### Typography by Component Type

**Navigation:**
- Default: `text-sm font-medium text-gray-700`
- Active: `text-sm font-semibold text-blue-600`

**Headings:**
- Hero: `text-5xl font-bold tracking-tight sm:text-6xl md:text-7xl`
- Section: `text-4xl font-semibold sm:text-5xl`
- Card: `text-lg font-semibold text-gray-900`

**Body Text:**
- Primary: `text-base text-gray-700`
- Secondary: `text-sm text-gray-600`
- Helper: `text-xs text-gray-500`

---

## Spacing System

### Most Used Spacing Values
- **Padding**: 2, 4, 6, 8 (most common)
- **Margin**: 2, 4, 6, 10
- **Gap**: 2, 3, 4, 6, 8

### Common Spacing Patterns

**Buttons:**
```erb
<!-- Small -->
class="px-3 py-1"

<!-- Medium (Most Common) -->
class="px-4 py-2"

<!-- Large -->
class="px-6 py-3"
```

**Cards/Containers:**
```erb
<!-- Standard Card -->
class="p-4" or class="p-6"

<!-- Responsive Card -->
class="p-4 sm:p-6"
```

**Sections:**
```erb
<!-- Standard Section -->
class="py-10"

<!-- Hero/Marketing Section -->
class="py-24 sm:py-32"
```

**Form Spacing:**
```erb
<!-- Field Groups -->
class="space-y-4" or class="space-y-6"

<!-- Label to Input -->
class="mt-1" or class="mt-2"
```

---

## Component Patterns

### Buttons

**Primary Button:**
```erb
class="inline-flex items-center justify-center gap-x-2 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
```

**Secondary Button:**
```erb
class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all"
```

**Icon Button:**
```erb
class="p-1 rounded-full hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
```

### Form Elements

**Text Input/Select:**
```erb
class="w-full px-4 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 text-sm"
```

**Label:**
```erb
class="block text-sm font-medium text-gray-700"
```

**Error Message:**
```erb
class="mt-2 text-sm text-red-600"
```

### Cards

**Basic Card:**
```erb
class="bg-white rounded-lg shadow-md p-6 transition-all hover:shadow-lg"
```

**Card with Header:**
```erb
<div class="bg-white rounded-lg shadow-md p-6 transition-all hover:shadow-lg">
  <div class="flex items-center mb-4">
    <h3 class="font-medium text-gray-900">Card Title</h3>
  </div>
  <!-- Content -->
</div>
```

### Section Card Pattern

The standard card layout for assignment sections:

```erb
<!-- Standard Section Card -->
<div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
  <div class="px-6 py-4 border-b border-gray-200">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-semibold text-gray-900 flex items-center">
        <%= render "shared/icons/[icon_name]", class: "w-5 h-5 mr-2 text-blue-500" %>
        Section Title
      </h2>
      <a href="/link" class="text-sm text-blue-600 hover:text-blue-800 font-medium">
        View details →
      </a>
    </div>
  </div>
  <div class="px-6 py-4">
    <!-- Content with proper spacing -->
  </div>
</div>
```

**Criteria Lists (Rubric Style):**
```erb
<div class="space-y-4">
  <div class="border-l-4 border-blue-500 pl-4 py-2">
    <h3 class="font-medium text-gray-900 mb-1">Title</h3>
    <p class="text-gray-600 text-sm">Description text</p>
  </div>
</div>
```

**Student Work Lists:**
```erb
<div class="divide-y divide-gray-200">
  <a href="/student_works/:id" class="block px-6 py-4 hover:bg-gray-50 transition-colors">
    <div class="flex items-start justify-between">
      <div class="flex-1">
        <h3 class="text-sm font-medium text-gray-900">Title</h3>
        <p class="text-sm text-gray-500 mt-1">Timestamp</p>
      </div>
      <span class="badge ml-4">Status</span>
    </div>
  </a>
</div>
```

### Alerts

**Error Alert:**
```erb
class="mb-4 p-3 bg-red-100 text-red-800 rounded-md flex items-start"
```

**With Border Accent:**
```erb
class="mb-6 border-l-4 border-red-500 bg-red-50 px-4 py-3"
```

### Navigation

**Nav Link (Active):**
```erb
class="group flex gap-x-3 rounded-md p-2 text-sm/6 font-semibold bg-gray-50 text-blue-600"
```

**Nav Link (Inactive):**
```erb
class="group flex gap-x-3 rounded-md p-2 text-sm/6 font-semibold text-gray-700 hover:bg-gray-50 hover:text-blue-600"
```

### Icons

**Standard Sizes:**
```erb
<!-- Small -->
class="w-4 h-4"

<!-- Medium (Most Common) -->
class="w-5 h-5"

<!-- Large -->
class="w-6 h-6"

<!-- Avatar/Extra Large -->
class="w-12 h-12"
```

---

## Layout Patterns

### Container Widths
```erb
<!-- Main Container -->
class="max-w-7xl mx-auto"

<!-- Content Containers -->
class="max-w-2xl mx-auto"  <!-- Narrow -->
class="max-w-3xl mx-auto"  <!-- Medium -->
class="max-w-4xl mx-auto"  <!-- Wide -->
```

### Standard Page Layout
```erb
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <!-- Content -->
</div>
```

### Two-Column Layout
```erb
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
  <div class="md:col-span-2">
    <!-- Main content -->
  </div>
  <div>
    <!-- Sidebar -->
  </div>
</div>
```

### Card Grid
```erb
<!-- Responsive 3-column grid -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
  <!-- Cards -->
</div>
```

### Sidebar Layout (Desktop)
```erb
<!-- Fixed Sidebar -->
<div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
  <!-- Sidebar content -->
</div>

<!-- Main Content -->
<div class="lg:pl-72">
  <main class="py-10">
    <div class="px-4 sm:px-6 lg:px-8">
      <!-- Content -->
    </div>
  </main>
</div>
```

---

## Interactive States

### Hover States
- Buttons: `hover:bg-blue-700` (darken) or `hover:bg-gray-50` (lighten)
- Cards: `hover:shadow-lg`
- Links: `hover:text-blue-600`, `hover:bg-blue-50`
- Icons: `hover:text-gray-500`

### Focus States
- Inputs: `focus:ring-1 focus:ring-blue-500 focus:border-blue-500`
- Buttons: `focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500`
- Links: `focus:outline-none`

### Active States
- Navigation: `bg-gray-50 text-blue-600`
- Buttons: Active states follow hover patterns

### Disabled States
- Inputs: `bg-gray-100 text-gray-500`
- Buttons: `opacity-50 cursor-not-allowed`

---

## Responsive Patterns

### Breakpoint Usage
1. **`sm:` (640px)** - Most frequently used
2. **`lg:` (1024px)** - Second most common
3. **`md:` (768px)** - Used for specific layout needs
4. **`xl:` (1280px)** - Rarely used
5. **`2xl:` (1536px)** - Not used

### Common Responsive Patterns

**Text Scaling:**
```erb
<!-- Hero Title -->
class="text-5xl sm:text-6xl md:text-7xl"

<!-- Section Header -->
class="text-4xl sm:text-5xl"

<!-- Body Text -->
class="text-xs sm:text-sm"
```

**Spacing:**
```erb
<!-- Padding -->
class="px-4 sm:px-6 lg:px-8"

<!-- Section Spacing -->
class="py-24 sm:py-32"

<!-- Gaps -->
class="gap-4 sm:gap-6"
```

**Layout Changes:**
```erb
<!-- Column to Row -->
class="flex flex-col sm:flex-row"

<!-- Grid Responsive -->
class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"

<!-- Show/Hide -->
class="hidden lg:block"
class="lg:hidden"
```

---

## Stimulus Controllers

The application uses these Stimulus controllers for interactivity:
- `doc-picker` - Document selection interface
- `dropdown` - Dropdown menu functionality
- `feedback-tone-slider` - Slider UI controls
- `layout` - Layout management (sidebar, mobile menu)
- `rubric-toggle` - Toggle switch functionality

### Common Data Attributes
```erb
<!-- Dropdown -->
data-controller="dropdown"
data-dropdown-target="menu"
data-action="click->dropdown#toggle"

<!-- Toggle -->
data-controller="rubric-toggle"
data-action="click->rubric-toggle#toggle"
```

---

## Implementation Guidelines

### When Creating New Views

1. **Start with mobile**: Build mobile-first using base classes
2. **Add responsive prefixes**: Layer on `sm:`, `lg:` as needed
3. **Use existing patterns**: Reference this guide for consistent styling
4. **Maintain spacing scale**: Stick to 2, 4, 6, 8 for most spacing
5. **Follow color semantics**: Use blue for primary, gray for neutral, semantic colors for states

### Component Consistency

1. **Buttons**: Always include focus states and transitions
2. **Forms**: Use consistent field styling and error patterns
3. **Cards**: Apply standard shadow and hover effects
4. **Navigation**: Follow active/inactive state patterns

### Accessibility

1. Always include focus rings on interactive elements
2. Use semantic HTML with proper ARIA attributes
3. Ensure sufficient color contrast (follow WCAG guidelines)
4. Include screen reader text where needed (`.sr-only`)

---

## Assignment View Spacing Standards

Based on successful implementations:

### Section Spacing
- Between sections: `mb-6`
- Card padding: `px-6 py-4`
- Header separator: `border-b border-gray-200`

### Content Spacing
- Criteria lists: `space-y-4` with `py-2` per item
- Student work items: `divide-y divide-gray-200`
- Text content: Use `prose max-w-none` for formatted text

### Interactive Elements
- Hover states: `hover:bg-gray-50 transition-colors`
- Links: `text-blue-600 hover:text-blue-800 font-medium`
- Badges: Right-aligned with `ml-4` spacing

---

This design system represents the actual patterns found in the codebase and should be used as the authoritative reference for creating new views that align with the existing design.