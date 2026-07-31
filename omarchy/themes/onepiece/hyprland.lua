-- Window borders for the One Piece theme.
--
-- Omarchy generates this file from default/themed/hyprland.lua.tpl when a
-- theme does not ship one, and that generated version uses the raw accent at
-- full opacity. At the accent's saturation that reads as a hard neon line
-- against the dark background, especially once corners are rounded.
--
-- Shipping the file suppresses generation entirely: omarchy-theme-set-templates
-- only renders a template when the output path does not already exist.
--
-- The accent hue is kept so focus still reads as "One Piece red", but the alpha
-- is dropped so the border sits behind the content instead of competing with
-- it. Border width lives in config/hypr/looknfeel.lua, which is theme-agnostic.

local active_border_color = "rgba(E55A6A99)"
local inactive_border_color = "rgba(2D3A4D66)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
