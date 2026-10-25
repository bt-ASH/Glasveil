-- Matugen generated catppuccin overrides for nvim
local palette = {
  bg = "{{colors.surface_container.default.hex}}",
  fg = "{{colors.on_surface.default.hex}}",
  primary = "{{colors.primary.default.hex}}",
  secondary = "{{colors.secondary.default.hex}}",
  tertiary = "{{colors.tertiary.default.hex}}",
  error = "{{colors.error.default.hex}}",
}

local function hex_highlight(name, bg, fg, opts)
  local cmd = "highlight " .. name
  if bg then cmd = cmd .. " guibg=" .. bg end
  if fg then cmd = cmd .. " guifg=" .. fg end
  if opts then cmd = cmd .. " " .. opts end
  vim.cmd(cmd)
end

-- make catppuccin recolor when changing palette (source this file after matugen)
vim.cmd("colorscheme catppuccin")
hex_highlight("Normal", nil, palette.fg)
hex_highlight("FloatBorder", palette.tertiary, palette.fg, "gui=bold")
hex_highlight("TelescopeBorder", palette.tertiary, nil, "gui=bold")
