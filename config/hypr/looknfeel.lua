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
    -- Match the 34px shell pills: their circular end-cap radius is 17px.
    -- A power of 2 keeps both surfaces on the same circular curvature.
    rounding = 17,
    rounding_power = 2,

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

-- Keep Omarchy/Hyprland's native animation tree for windows and layers.
-- Only opt regular workspaces back into the stock full-distance slide style;
-- a higher speed keeps the transition visible without a lingering exit.
hl.animation({ leaf = "workspaces", enabled = true, speed = 8.5, bezier = "default", style = "slide" })

-- XWayland fonts follow an X resource, not a Wayland scale. This monitor runs
-- at scale 2 (see monitors.lua's GDK_SCALE), which native Wayland apps honour
-- on their own; an XWayland Qt app such as WeChat has no such channel and
-- renders at 96 DPI, i.e. half size. Xft.dpi = 96 * 2 puts it on the same
-- footing. Merged once per session, after Xwayland is up, because the resource
-- lives on the X server that Hyprland starts. Keep 192 in step with the
-- monitor's scale if that ever changes.
o.exec_on_start(
  "bash -c 'for i in $(seq 40); do xrdb -query >/dev/null 2>&1 && break; sleep 0.25; done; "
    .. "printf \"Xft.dpi: 192\\n\" | xrdb -merge'"
)

-- Frost the bar so the theme can make it transparent and still stay readable.
-- Omarchy already rules this namespace for animation; layer rules accumulate,
-- so this adds blur without disturbing that. `ignore_alpha` keeps the fully
-- transparent parts of the layer from being blurred into a visible slab.
hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur = true,
  ignore_alpha = 0.1,
})
