-- Mock of Hyprland's Lua `hl` API, mirroring share/hypr/stubs/hl.meta.lua
-- (Hyprland 0.55.4). Used to load-test ~/.config/hypr/hyprland.lua WITHOUT a
-- running compositor: any unknown top-level/dsp.* call fails here exactly as
-- Hyprland would ("attempt to call nil value ...").
--
-- Usage:  lua hl-mock.lua <hyprland.lua>
local fn = function() end

local nsWorkspace = {}
for _, k in ipairs({ "move", "rename", "swap_monitors", "toggle_special" }) do nsWorkspace[k] = fn end

local nsWindow = {}
for _, k in ipairs({
  "alter_zorder", "bring_to_top", "center", "clear_tags", "close", "cycle_next",
  "deny_from_group", "drag", "float", "fullscreen", "fullscreen_state", "kill",
  "move", "pin", "pseudo", "resize", "set_prop", "signal", "swap", "tag",
  "toggle_swallow",
}) do nsWindow[k] = fn end

local nsCursor = {}
for _, k in ipairs({ "move", "move_to_corner" }) do nsCursor[k] = fn end

local nsGroup = {}
for _, k in ipairs({ "active", "lock", "lock_active", "move_window", "next", "prev", "toggle" }) do nsGroup[k] = fn end

local dsp = {}
for _, k in ipairs({
  "dpms", "event", "exec_cmd", "exec_raw", "exit", "focus", "force_idle",
  "force_renderer_reload", "global", "layout", "no_op", "pass", "send_key_state",
  "send_shortcut", "submap",
}) do dsp[k] = fn end
dsp.cursor = nsCursor
dsp.group = nsGroup
dsp.window = nsWindow
dsp.workspace = nsWorkspace

local hl = {}
for _, k in ipairs({
  "animation", "bind", "config", "curve", "define_submap", "device", "dispatch",
  "env", "exec_cmd", "gesture", "layer_rule", "monitor", "on", "permission",
  "timer", "unbind", "version", "window_rule", "workspace_rule",
  "get_active_monitor", "get_active_special_workspace", "get_active_window",
  "get_active_workspace", "get_config", "get_current_submap", "get_cursor_pos",
  "get_last_window", "get_last_workspace", "get_layers", "get_monitor",
  "get_monitor_at", "get_monitor_at_cursor", "get_monitors",
  "get_urgent_window", "get_window", "get_windows", "get_workspace",
  "get_workspace_windows", "get_workspaces",
}) do hl[k] = fn end
hl.dsp = dsp
hl.layout = { register = fn }
hl.notification = { create = fn, get = fn }
hl.plugin = { load = fn }

_G.hl = hl

local target = arg[1]
assert(target, "usage: lua hl-mock.lua <hyprland.lua>")
local chunk, err = loadfile(target)
assert(chunk, "load error: " .. tostring(err))
chunk()
print("OK: " .. target .. " loaded against mock hl API (no nil-value errors)")