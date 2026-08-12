# hyprpaper >= 0.8 (hyprtoolkit rewrite): no more `preload` / `wallpaper = mon,path`
# one-liners. Wallpapers are anonymous `wallpaper { }` blocks; empty `monitor` =
# fallback for all monitors. Rendered from themes/theme-module.nix.
wallpaper {
    monitor = 
    path = {{ wallpaper }}
    fit_mode = cover
}
splash = false
