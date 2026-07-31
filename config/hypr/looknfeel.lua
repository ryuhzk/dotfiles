-- Desktop look and feel.
--
-- Omarchy loads this file after its own defaults and after the current theme's
-- Hyprland overrides, so everything here wins. Window border colors are
-- deliberately not set: `omarchy theme set` owns them, and overriding them here
-- would detach the borders from the active theme.
--
-- Motion follows Material 3 expressive easing. Spatial properties (position,
-- size) overshoot slightly before settling; effect properties (opacity) never
-- overshoot, because a fade past 100% has nowhere to go.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,

    -- A hairline is enough to mark focus once the border color is muted; the
    -- stock 2px reads as a hard outline at the accent's saturation. The color
    -- itself stays with the theme.
    border_size = 1,

    -- Empty space held between workspaces while they slide past each other.
    gaps_workspaces = 50,

    resize_on_border = true,
    no_focus_fallback = true,

    snap = {
      enabled = true,
      window_gap = 4,
      monitor_gap = 8,
      respect_gaps = true,
    },
  },

  decoration = {
    -- rounding_power 2 is a true circular corner; higher values approach a
    -- squircle. 2.5 reads as a softened corner rather than an obvious squircle.
    rounding = 14,
    rounding_power = 2.5,

    blur = {
      enabled = true,
      size = 10,
      passes = 3,

      -- xray blurs against the wallpaper instead of the windows underneath, so
      -- stacked transparent windows stay legible.
      xray = true,
      special = false,
      new_optimizations = true,

      noise = 0.05,
      contrast = 0.89,
      brightness = 1.0,
      vibrancy = 0.5,
      vibrancy_darkness = 0.5,

      popups = false,

      -- Fcitx5 candidate windows are layer surfaces; blurring them keeps the
      -- input method consistent with the rest of the desktop.
      input_methods = true,
      input_methods_ignorealpha = 0.8,
    },

    shadow = {
      enabled = true,
      range = 20,
      offset = { 0, 2 },
      render_power = 10,
      color = "rgba(00000020)",
    },

    -- Just enough separation to tell focused from unfocused at a glance.
    dim_inactive = true,
    dim_strength = 0.05,
    dim_special = 0.2,
  },

  animations = {
    enabled = true,
  },
})

-- Easing curves. Control points with y > 1 overshoot the target and settle back.
hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { { 0.38, 1.21 }, { 0.22, 1.00 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.70 }, { 0.10, 1.00 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.30, 0.00 }, { 0.80, 0.15 } } })
hl.curve("menuDecel", { type = "bezier", points = { { 0.10, 1.00 }, { 0.00, 1.00 } } })
hl.curve("menuAccel", { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })

-- Holds near the start before releasing, so a layer fades out only once its
-- shrink animation has visibly begun.
hl.curve("stall", { type = "bezier", points = { { 1.00, -0.10 }, { 0.70, 0.85 } } })

-- Windows.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedDecel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "expressiveDefaultSpatial", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "emphasizedDecel" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "emphasizedDecel" })

-- Layer surfaces: the bar, launcher, notifications, and menus.
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "menuAccel", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 0.5, bezier = "menuDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "stall" })

-- Workspaces. Omarchy disables this animation by default, which is what makes
-- workspace switching feel instant rather than spatial.
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menuDecel", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.8, bezier = "expressiveDefaultSpatial", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })

-- Frost the bar so the theme can make it transparent and still stay readable.
-- Omarchy already rules this namespace for animation; layer rules accumulate,
-- so this adds blur without disturbing that. `ignore_alpha` keeps the fully
-- transparent parts of the layer from being blurred into a visible slab.
hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur = true,
  ignore_alpha = 0.1,
})
