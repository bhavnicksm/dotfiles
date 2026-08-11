# Omarchy-style hyprlock — blurred wallpaper + centered password field.
# Colors are rendered from themes/palettes.nix by themes/theme-module.nix
# ({{ lockInner }} etc. are rgba() strings computed at build time).

general {
    hide_cursor = false
}

animations {
    enabled = true
    bezier = linear, 1, 1, 0, 0
    animation = fadeIn, 1, 5, linear
    animation = fadeOut, 1, 5, linear
    animation = inputFieldDots, 1, 2, linear
}

background {
    monitor =
    path = {{ lockBg }}
    blur_passes = 4
    blur_size = 8
    noise = 0.03
    contrast = 0.92
    brightness = 1.0
    vibrancy = 0.2
}

# Mirrors Omarchy's lock: 381x67 field, 3px outline, rounded to Hyprland's
# decoration:rounding (6), filled with the theme background at 80% alpha.
input-field {
    monitor =
    size = 381, 67
    outline_thickness = 3
    dots_size = 0.15
    dots_spacing = 0.2
    dots_center = true
    inner_color = {{ lockInner }}
    outer_color = {{ lockOuter }}
    check_color = {{ lockCheck }}
    fail_color = {{ lockFail }}
    font_color = {{ lockFont }}
    fade_on_empty = true
    rounding = 6
    placeholder_text = Enter Password
    fail_text = $FAIL
    position = 0, 0
    halign = center
    valign = center
}