-- 'c → ç for Chromium/Electron/etc that ignore ~/.XCompose and use locale Compose.
hl.env("LC_CTYPE", "pt_BR.UTF-8")

hl.config({
  input = {
    -- US International: ' then a/e/i/o/u → á/é/í/ó/ú ; ç via XCompose
    kb_layout = "us",
    kb_variant = "intl",
    kb_options = "",
    scroll_factor = 4.0,
    emulate_discrete_scroll = 2,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 1.5,
    },
  },
})


-- Remmina/TigerVNC → Mac Screen Sharing. Hyprland caps these at 10.
o.window("org.remmina.Remmina", { scroll_mouse = 10.0, scroll_touchpad = 10.0 })
o.window("(^Vncviewer$|TigerVNC)", { scroll_mouse = 10.0, scroll_touchpad = 10.0 })

hl.env("PATH", (os.getenv("HOME") .. "/.local/bin:") .. (os.getenv("PATH") or "/usr/bin"))
