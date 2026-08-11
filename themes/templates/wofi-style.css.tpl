/* Generated from themes/templates/wofi-style.css.tpl — edits go in the template. */
window {
    margin: 0px;
    border: 1px solid {{ accent }};
    background-color: {{ background }};
    color: {{ foreground }};
}

#input {
    margin: 5px;
    border: none;
    color: {{ foreground }};
    background-color: {{ dark_background }};
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: {{ background }};
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: {{ background }};
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: {{ foreground }};
}

#entry:selected {
    background-color: {{ selection }};
    color: {{ foreground }};
}
