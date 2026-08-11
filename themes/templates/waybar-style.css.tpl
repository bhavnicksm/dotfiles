/* Generated from themes/templates/waybar-style.css.tpl — edits go in the template. */
@define-color background {{ background }};
@define-color foreground {{ foreground }};
@define-color accent {{ accent }};
@define-color muted {{ muted }};
@define-color selection {{ selection }};
@define-color red {{ red }};
@define-color yellow {{ yellow }};
@define-color green {{ green }};

* {
    font-size: 12px;
    font-family: "JetBrainsMono Nerd Font";
    min-height: 0;
    border: none;
    border-radius: 0;
}

window#waybar {
    background: @background;
    color: @foreground;
    padding: 0;
    min-height: 26px;
}

.modules-left {
    margin-left: 8px;
}

.modules-right {
    margin-right: 8px;
}

/* Workspaces — flat, minimal, Omarchy-style */
#workspaces button {
    all: unset;
    padding: 0 6px;
    margin: 0 1.5px;
    min-width: 9px;
    color: @muted;
}

#workspaces button:hover {
    color: @foreground;
}

#workspaces button.active {
    color: @foreground;
    border-bottom: 2px solid @accent;
}

#workspaces button.empty {
    opacity: 0.5;
}

#workspaces button.empty.active {
    color: @foreground;
    border-bottom: 2px solid @accent;
}

/* Custom launcher button */
#custom-omarchy {
    min-width: 12px;
    margin: 0 7.5px;
    color: @foreground;
}

/* Clock */
#clock {
    color: @foreground;
    font-weight: normal;
    padding-left: 10px;
    padding-right: 10px;
}

/* Right-side modules */
#pulseaudio,
#bluetooth,
#network,
#battery {
    padding: 4px 6px;
    transition: all .3s ease;
}

#pulseaudio:hover,
#bluetooth:hover,
#network:hover,
#battery:hover,
#custom-colorpicker:hover {
    color: @accent;
}

/* Expand drawer */
#group-expand {
    padding: 0px;
    transition: all .3s ease;
}

#custom-expand {
    padding: 4px 6px;
    color: @foreground;
    transition: all .3s ease;
}

#custom-expand:hover {
    color: @accent;
}

#custom-colorpicker {
    padding: 4px 6px;
}

#cpu,
#memory,
#temperature {
    padding: 4px 6px;
    transition: all .3s ease;
    color: @muted;
}

#custom-endpoint {
    color: transparent;
    text-shadow: 0px 0px 1.5px rgba(0, 0, 0, .5);
}

/* Battery states */
#battery.charging {
    color: @green;
}

#battery.warning:not(.charging) {
    color: @yellow;
}

#battery.critical:not(.charging) {
    color: @red;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

@keyframes blink {
    to {
        opacity: 0.5;
    }
}

/* Tray */
#tray {
    padding: 4px 8px;
    padding-left: 4px;
    transition: all .3s ease;
}

#tray menu * {
    padding: 4px 6px;
}

#tray menu separator {
    padding: 4px 6px;
}

/* Tooltip */
tooltip {
    background: @background;
    color: @foreground;
    border: 1px solid @accent;
    border-radius: 3px;
    padding: 6px;
    font-weight: bold;
}

tooltip * {
    color: @foreground;
}
