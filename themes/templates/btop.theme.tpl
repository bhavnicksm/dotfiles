# Generated from themes/templates/btop.theme.tpl — edits go in the template.

# Main text color
theme[main_fg]="{{ foreground }}"

# Main background color
theme[main_bg]="{{ background }}"

# Title color for boxes
theme[title]="{{ foreground }}"

# Highlight color for keyboard shortcuts
theme[hi_fg]="{{ accent }}"

# Background color of selected item in processes box
theme[selected_bg]="{{ selection }}"

# Foreground color of selected item in processes box
theme[selected_fg]="{{ foreground }}"

# Color of inactive/disabled text
theme[inactive_fg]="{{ muted }}"

# Misc colors for processes box including mini cpu graphs, details memory graph and details status text
theme[proc_misc]="{{ accent }}"

# Cpu box outline color
theme[cpu_box]="{{ green }}"

# Memory/disks box outline color
theme[mem_box]="{{ yellow }}"

# Net up/down box outline color
theme[net_box]="{{ magenta }}"

# Processes box outline color
theme[proc_box]="{{ cyan }}"

# Box divider line and small boxes line color
theme[div_line]="{{ muted }}"

# Temperature graph colors
theme[temp_start]="{{ green }}"
theme[temp_mid]="{{ yellow }}"
theme[temp_end]="{{ red }}"

# CPU graph colors
theme[cpu_start]="{{ green }}"
theme[cpu_mid]="{{ yellow }}"
theme[cpu_end]="{{ red }}"

# Mem/Disk free meter
theme[free_start]="{{ green }}"

# Mem/Disk cached meter
theme[cached_start]="{{ yellow }}"

# Mem/Disk available meter
theme[available_start]="{{ yellow }}"

# Mem/Disk used meter
theme[used_start]="{{ red }}"

# Download graph colors
theme[download_start]="{{ magenta }}"
theme[download_mid]="{{ blue }}"
theme[download_end]="{{ cyan }}"

# Upload graph colors
theme[upload_start]="{{ magenta }}"
theme[upload_mid]="{{ blue }}"
theme[upload_end]="{{ cyan }}"
