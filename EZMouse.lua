-- ====================
-- || EZMouse v0.4.0 ||
-- ====================

dofile_once("data/scripts/lib/utilities.lua")

local path
local mouse_state = {
  left_down = false,
  right_down = false,
  sx = 0,
  sy = 0,
  world_x = 0,
  world_y = 0,
  dx = 0,
  dy = 0
}
local resize_start_x, resize_start_y = 0, 0
local resize_start_sx, resize_start_sy = 0, 0
local resize_start_width, resize_start_height = 0, 0
local resize_last_width_fired, resize_last_height_fired = 0, 0
local current_widget_id = 1
local do_draw_resize_cursor = false
local resize_handle_size = 8
local drag_tolerance = 2
local drag_tolerance_sq = drag_tolerance * drag_tolerance

local function are_floats_equal(f1, f2)
  return math.abs(f1 - f2) < 0.0001
end

local function is_inside_rect(x, y, rect_x, rect_y, width, height)
	return not ((x < rect_x) or (x > rect_x + width) or (y < rect_y) or (y > rect_y + height))
end

dofile_once("data/scripts/debug/keycodes.lua")
local dragging_widget = {
  last_frame_ran = 0,
  callbacks = {
    drag_start = function(result) end,
    was_dragged = function(result) end,
    drag_end = function(result) end,
  }
}
-- Blocks mouse events and catches drag events
local function render_dragging_widget_at_mouse_pos(gui, current_x, current_y, callbacks)
  if not dragging_widget.drag_start_init then
    callbacks = callbacks or {}
    dragging_widget.callbacks.drag_start = callbacks.drag_start or dragging_widget.callbacks.drag_start
    dragging_widget.callbacks.was_dragged = callbacks.was_dragged or dragging_widget.callbacks.was_dragged
    dragging_widget.callbacks.drag_end = callbacks.drag_end or dragging_widget.callbacks.drag_end
  end
  -- We only need to render it once, it it has already been calculated this frame, return
  if dragging_widget.last_frame_ran >= GameGetFrameNum() then
    return
  end
  dragging_widget.last_frame_ran = GameGetFrameNum()
  dragging_widget.result = dragging_widget.result or {}
  dragging_widget.result.dx = 0
  dragging_widget.result.dy = 0
  dragging_widget.result.was_dragged = false
  GuiIdPushString(gui, "boo")
  GuiOptionsAddForNextWidget(gui, GUI_OPTION.NoPositionTween)
  GuiZSetForNextWidget(gui, -999999)
  -- Draw an invisible image that blocks mouse clicks, so as to not shoot wands accidentally
  GuiImage(gui, 3, mouse_state.sx - 25, mouse_state.sy - 25, path .. "invis.png", 1, 1, 1)
  GuiIdPop(gui)
  if InputIsMouseButtonJustDown(Mouse_left) then
    dragging_widget.drag_start_init = { x = mouse_state.sx, y = mouse_state.sy }
    dragging_widget.result.start_x = current_x -- The OG position the item was dragged from
    dragging_widget.result.start_y = current_y
    dragging_widget.result.drag_offset_x = dragging_widget.drag_start_init.x - current_x
    dragging_widget.result.drag_offset_y = dragging_widget.drag_start_init.y - current_y
  end
  local dist_moved_sq = 0
  if dragging_widget.drag_start_init then
    local dx = math.abs(dragging_widget.drag_start_init.x - mouse_state.sx)
    local dy = math.abs(dragging_widget.drag_start_init.y - mouse_state.sy)
    dist_moved_sq = dx * dx + dy * dy
  end
  if InputIsMouseButtonDown(Mouse_left) then
    if dist_moved_sq > drag_tolerance_sq and not dragging_widget.last_x then
      dragging_widget.last_x = current_x
      dragging_widget.last_y = current_y
      dragging_widget.callbacks.drag_start(dragging_widget.result)
    elseif dragging_widget.last_x then
      dragging_widget.result.dx = (mouse_state.sx - dragging_widget.result.drag_offset_x) - dragging_widget.last_x
      dragging_widget.result.dy = (mouse_state.sy - dragging_widget.result.drag_offset_y) - dragging_widget.last_y
      dragging_widget.last_x = dragging_widget.last_x + dragging_widget.result.dx
      dragging_widget.last_y = dragging_widget.last_y + dragging_widget.result.dy
      if dragging_widget.result.dx ~= 0 or dragging_widget.result.dy ~= 0 then
        dragging_widget.result.was_dragged = true
        dragging_widget.callbacks.was_dragged(dragging_widget.result)
      end
    end
  elseif InputIsMouseButtonJustUp(Mouse_left) then
    if dragging_widget.last_x then
      dragging_widget.callbacks.drag_end(dragging_widget.result)
    end
    dragging_widget.drag_start_init = nil
    dragging_widget.last_x = nil
    dragging_widget.last_y = nil
    dragging_widget.callbacks = {
      drag_start = function(result) end,
      was_dragged = function(result) end,
      drag_end = function(result) end,
    }
  end
end

local function draw_resize_cursor(gui, handle_index, x, y)
  local sprite = handle_index % 2 == 0 and "horizontal" or "diagonal"
  local rotations = {
    { x = -(25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = math.rad(90), },
    { x = -(25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = math.rad(90), },
    { x = (25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = 0, },
    { x = (25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = 0, },
    { x = -(25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = math.rad(90), },
    { x = -(25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = math.rad(90), },
    { x = (25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = 0, },
    { x = (25 / 2) + 0.5, y = (25 / 2) + 0.5, rot = 0, }
  }
  GuiImage(gui, 87878, mouse_state.sx - rotations[handle_index].x, mouse_state.sy - rotations[handle_index].y, path .. "cursor_resize_" .. sprite .. ".png", 1, 1, 1, rotations[handle_index].rot)
end

local function calculate_handle_props(self, resize_handle_size)
  return {
    { x = self.x - (resize_handle_size/2),              y = self.y - (resize_handle_size/2),               width = resize_handle_size,              height = resize_handle_size,               move = {-1,-1} }, -- top left
    { x = self.x + (resize_handle_size/2),              y = self.y - (resize_handle_size/2),               width = self.width - resize_handle_size, height = resize_handle_size,               move = {0,-1}  }, -- top
    { x = self.x + self.width - (resize_handle_size/2), y = self.y - (resize_handle_size/2),               width = resize_handle_size,              height = resize_handle_size,               move = {1,-1}  }, -- top right
    { x = self.x + self.width - (resize_handle_size/2), y = self.y + (resize_handle_size/2),               width = resize_handle_size,              height = self.height - resize_handle_size, move = {1,0}   }, -- right
    { x = self.x + self.width - (resize_handle_size/2), y = self.y + self.height - (resize_handle_size/2), width = resize_handle_size,              height = resize_handle_size,               move = {1,1}   }, -- bottom right
    { x = self.x + (resize_handle_size/2),              y = self.y + self.height - (resize_handle_size/2), width = self.width - resize_handle_size, height = resize_handle_size,               move = {0,1}   }, -- bottom
    { x = self.x - (resize_handle_size/2),              y = self.y + self.height - (resize_handle_size/2), width = resize_handle_size,              height = resize_handle_size,               move = {-1,1}  }, -- bottom left
    { x = self.x - (resize_handle_size/2),              y = self.y + (resize_handle_size/2),               width = resize_handle_size,              height = self.height - resize_handle_size, move = {-1,0}  }, -- left
  }
end

local function fire_event(self, name, ...)
  for i, listener in ipairs(self.event_listeners[name]) do
    listener(self, ...)
  end
end

local widget_instances = setmetatable({}, { __mode = "v" })
-- The privates should be read-only from outside
local widget_privates = setmetatable({}, { __mode = "k" })
local Widget = {}
function Widget:__index(key)
  if key == "_members" then
    error("Don't touch the internals :)", 2)
  end
  -- Private getter (read-only)
  if widget_privates[self][key] ~= nil then
    return widget_privates[self][key]
  end
  -- Static getter
  if rawget(Widget, key) ~= nil then
    return rawget(Widget, key)
  end
  -- Public getter
  return self._members[key]
end
function Widget:__newindex(key, value)
  if widget_privates[self][key] ~= nil then
    error("'"..key.."' is read-only.", 2)
  end
  self._members[key] = value
end
local function validate_constraints(c)
  c = c or {}
  if type(c) ~= "table" then
    error("'constraints' must be a table", 3)
  end
  for k, v in pairs(c) do
    if k ~= "left" and k~= "top" and k ~= "right" and k~= "bottom" then
      error(("'%s' is not a valid constraint type"):format(k), 3)
    end
    if type(v) ~= "number" then
      error(("Value for constraints.'%s' must be of type 'number'."):format(k), 3)
    end
  end
  return c
end
-- Constructor
function Widget:__call(props)
  if type(props) ~= "table" then
    error("'props' needs to be a table.", 2)
  end

  -- This could probably be done better
  local instance = setmetatable({ _members = {
    x = props.x or 0,
    y = props.y or 0,
    z = props.z or 0,
    width = props.width or 100,
    height = props.height or 100,
    min_width = props.min_width or 1,
    min_height = props.min_height or 1,
    max_width = props.max_width or 999999,
    max_height = props.max_height or 999999,
    draggable = props.draggable == nil and true or not not props.draggable,
    drag_anchor = props.drag_anchor or nil, -- either "center", "top_left" or nil
    drag_granularity = props.drag_granularity or 0.1, -- NOT IMPLEMENTED
    resizable = not not props.resizable,
    resize_granularity = props.resize_granularity or 0.1,
    resize_symmetrical = not not props.resize_symmetrical,
    resize_keep_aspect_ratio = not not props.resize_keep_aspect_ratio,
    enabled = props.enabled == nil and true or not not props.enabled,
    hoverable = props.hoverable == nil and true or not not props.hoverable,
    constraints = validate_constraints(props.constraints),
    event_listeners = {
      mouse_down = {},
      mouse_up = {},
      drag = {},
      drag_start = {},
      drag_end = {},
      resize = {},
      resize_start = {},
      resize_end = {},
    }
  }}, Widget)
  widget_privates[instance] = {
    resizing = false,
    dragging = false,
    hovered = false,
    id = current_widget_id,
  }
  current_widget_id = current_widget_id + 1

  if instance.min_width > instance.width then
    error(string.format("min_width(%d) needs to be smaller than width(%d).", instance.min_width, instance.width), 2)
  end
  if instance.min_height > instance.height then
    error(string.format("min_height(%d) needs to be smaller than height(%d).", instance.min_height, instance.height), 2)
  end

  table.insert(widget_instances, instance)
  table.sort(widget_instances, function(a, b)
    return a.z < b.z
  end)

  return instance
end

function Widget:AddEventListener(event_name, listener)
  if not self.event_listeners[event_name] then
    error("No event by the name of '"..event_name.."'", 2)
  end
  table.insert(self.event_listeners[event_name], listener)
  return listener
end

function Widget:RemoveEventListener(event_name, listener)
  if not self.event_listeners[event_name] then
    error("No event by the name of '"..event_name.."'", 2)
  end
  for i, v in ipairs(self.event_listeners[event_name]) do
    if v == listener then
      table.remove(self.event_listeners[event_name], i)
      return
    end
  end
  error("Cannot remove a listener that was never registered.", 2)
end

function Widget:DebugDraw(gui, sprite)
  GuiIdPushString(gui, "EZMouse_debug_draw_" .. tostring(widget_privates[self].id))
  GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
  GuiZSetForNextWidget(gui, self.z)
  GuiImage(gui, 2, self.x, self.y, path .. (widget_privates[self].hovered and "green_square_10x10.png" or (sprite or "red") .. "_square_10x10.png"),0.5, self.width / 10, self.height / 10)
  if widget_privates[self].resize_handle_hovered or widget_privates[self].resize_handle_index then
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
    GuiZSetForNextWidget(gui, self.z - 0.5)
    GuiImage(gui, 3, widget_privates[self].resize_handle.x, widget_privates[self].resize_handle.y, path .. "green_square_10x10.png", 1, widget_privates[self].resize_handle.width / 10, widget_privates[self].resize_handle.height / 10)
  end
  GuiIdPop(gui)
end

function Widget:Destroy()
  for i=#widget_instances, 1, -1 do
    if widget_instances[i] == self then
      table.remove(widget_instances, i)
    end
  end
end

setmetatable(Widget, Widget)

-- These are for global events
local event_listeners = {
  mouse_down = {},
  mouse_up = {},
  mouse_move = {},
}

local function fire_global_event(name, ...)
  for i, listener in ipairs(event_listeners[name]) do
    listener(...)
  end
end

local function AddEventListener(event_name, listener)
  if not event_listeners[event_name] then
    error("No event by the name of '"..event_name.."'", 2)
  end
  table.insert(event_listeners[event_name], listener)
  return listener
end

local function RemoveEventListener(event_name, listener)
  if not event_listeners[event_name] then
    error("No event by the name of '"..event_name.."'", 2)
  end
  for i, v in ipairs(event_listeners[event_name]) do
    if v == listener then
      table.remove(event_listeners[event_name], i)
      return
    end
  end
  error("Cannot remove a listener that was never registered.", 2)
end

-- Keep track of which draggable was clicked on and is waiting for drag
local focused_draggable = nil
local mouse_loop_last_sx = 0
local mouse_loop_last_sy = 0
local function update(gui)
  if dragging_widget.drag_start_init then
    render_dragging_widget_at_mouse_pos(gui, dragging_widget.drag_start_init.x, dragging_widget.drag_start_init.y, dragging_widget.callbacks)
  end

	-- Get whatever state we can directly from the component
	if GameGetFrameNum() > 10 then
    mouse_state.left_down = InputIsMouseButtonDown(Mouse_left)
    mouse_state.left_up = InputIsMouseButtonJustUp(Mouse_left)
    mouse_state.left_pressed = InputIsMouseButtonJustDown(Mouse_left)
    mouse_state.right_down = InputIsMouseButtonDown(Mouse_right)
    mouse_state.right_up = InputIsMouseButtonJustUp(Mouse_right)
    mouse_state.right_pressed = InputIsMouseButtonJustDown(Mouse_right)

    if mouse_state.left_up then
      if focused_draggable then
        if mouse_state.left_up then fire_event(focused_draggable, "mouse_up", { button = "left"}) end
        if mouse_state.right_up then fire_event(focused_draggable, "mouse_up", { button = "right"}) end
      end
      focused_draggable = nil
    end

    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local mouse_raw_x, mouse_raw_y = InputGetMousePosOnScreen()
    mouse_state.sx, mouse_state.sy = mouse_raw_x * screen_width / 1280, mouse_raw_y * screen_height / 720
    -- Calculate mMouseDelta ourselves because the native one isn't consistent across all window sizes
    mouse_state.dx = mouse_state.sx - mouse_loop_last_sx
    mouse_state.dy = mouse_state.sy - mouse_loop_last_sy
    mouse_loop_last_sx = mouse_state.sx
    mouse_loop_last_sy = mouse_state.sy

    -- If a widget is being hovered, saves a reference to the instance, otherwise stays nil
    local hovered_draggable
    -- If one of a widget's resize handle is being hovered, saves a reference to the widget instance and the hovered resize handle, otherwise stays nil
    local resize_handle_hovered_draggable
    if not dragging_draggable and not resizing_draggable and not focused_draggable then
      -- Reset hover status of all widgets at the beginning of every loop
      for i, draggable in ipairs(widget_instances) do
        widget_privates[draggable].hovered = false
        widget_privates[draggable].resize_handle_hovered = nil
      end
      -- Check current hover status of all widgets, main area and resize handles
      for i, draggable in ipairs(widget_instances) do
        if draggable.enabled then
          local resize_handle_size_ = draggable.resizable and resize_handle_size or 0
          widget_privates[draggable].hovered = is_inside_rect(mouse_state.sx, mouse_state.sy, draggable.x + resize_handle_size_/2, draggable.y + resize_handle_size_/2, draggable.width - resize_handle_size_, draggable.height - resize_handle_size_)
          widget_privates[draggable].hovered = draggable.hoverable and widget_privates[draggable].hovered
          if widget_privates[draggable].hovered then
            hovered_draggable = draggable
            -- Only one should be able to be hovered at a time, so no need to continue
            break
          else
            local resize_handles = calculate_handle_props(draggable, resize_handle_size_)
            for i, handle in ipairs(resize_handles) do
              if is_inside_rect(mouse_state.sx, mouse_state.sy, handle.x, handle.y, handle.width, handle.height) then
                widget_privates[draggable].resize_handle_hovered = i
                widget_privates[draggable].resize_handle = resize_handles[i]
                resize_handle_hovered_draggable = { draggable = draggable, hovered_handle = resize_handles[i], handle_index = i }
                break
              end
            end
            if resize_handle_hovered_draggable then
              -- This is to break out of the widget_instances loop
              break
            end
          end
        end
      end
    end

    if hovered_draggable and hovered_draggable.draggable and not dragging_draggable then
      if mouse_state.left_pressed then
        focused_draggable = hovered_draggable
      end
      local draggable = hovered_draggable
      if mouse_state.left_pressed then fire_event(draggable, "mouse_down", { button = "left"}) end
      if mouse_state.right_pressed then fire_event(draggable, "mouse_down", { button = "right"}) end
      render_dragging_widget_at_mouse_pos(gui, draggable.x, draggable.y, {
        drag_start = function(result)
          widget_privates[draggable].dragging = true
          dragging_draggable = draggable
          fire_event(draggable, "drag_start")
        end,
        was_dragged = function(result)
          local drag_offset_x = result.drag_offset_x
          local drag_offset_y = result.drag_offset_y
          if draggable.drag_anchor == "center" then
            drag_offset_x = draggable.width / 2
            drag_offset_y = draggable.height / 2
          elseif draggable.drag_anchor == "top_left" then
            drag_offset_x = 0
            drag_offset_y = 0
          end
          draggable.x = math.min((draggable.constraints.right or 99999) - draggable.width, math.max(draggable.constraints.left or 0, mouse_state.sx - drag_offset_x))
          draggable.y = math.min((draggable.constraints.bottom or 99999) - draggable.height, math.max(draggable.constraints.top or 0, mouse_state.sy - drag_offset_y))
          fire_event(draggable, "drag", { dx = result.dx, dy = result.dy })
        end,
        drag_end = function(result)
          widget_privates[draggable].dragging = false
          dragging_draggable = nil
          fire_event(draggable, "drag_end", { start_x = result.start_x, start_y = result.start_y })
        end
      })
    end

    if resize_handle_hovered_draggable then
      local draggable = resize_handle_hovered_draggable.draggable
      if mouse_state.left_pressed then
        focused_draggable = draggable
      end
      render_dragging_widget_at_mouse_pos(gui, draggable.x, draggable.y, {
        drag_start = function(result)
          resizing_draggable = draggable
          widget_privates[draggable].hovered = false
          widget_privates[draggable].resize_handle_index = resize_handle_hovered_draggable.handle_index
          widget_privates[draggable].resize_handle = resize_handle_hovered_draggable.hovered_handle
          fire_event(draggable, "resize_start", { handle_index = resize_handle_hovered_draggable.handle_index })
          resize_start_sx = resize_handle_hovered_draggable.hovered_handle.x + (resize_handle_size / 2)
          resize_start_sy = resize_handle_hovered_draggable.hovered_handle.y + (resize_handle_size / 2)
          resize_start_x = draggable.x
          resize_start_y = draggable.y
          resize_start_width = draggable.width
          resize_start_height = draggable.height
          resize_last_width_fired = draggable.width -- For detecting whether it was resized or not (especially when quantized)
          resize_last_height_fired = draggable.height
          aspect_ratio = draggable.width / draggable.height
        end,
        was_dragged = function(result)
          local dx = mouse_state.sx - resize_start_sx
          local dy = mouse_state.sy - resize_start_sy
          local change_left = dx * -math.min(widget_privates[draggable].resize_handle.move[1], 0)
          local change_right = dx * math.max(widget_privates[draggable].resize_handle.move[1], 0)
          local change_top = dy * -math.min(widget_privates[draggable].resize_handle.move[2], 0)
          local change_bottom = dy * math.max(widget_privates[draggable].resize_handle.move[2], 0)

          local update_draggable = dofile_once(path .. "resize.lua")
          change_left, change_top, change_right, change_bottom = update_draggable({
            x = resize_start_x, y = resize_start_y,
            width = resize_start_width,
            height = resize_start_height,
            min_width = draggable.min_width,
            min_height = draggable.min_height,
            max_width = draggable.max_width,
            max_height = draggable.max_height,
            constraints = draggable.constraints,
            quantization = draggable.resize_granularity,
            symmetrical = draggable.resize_symmetrical,
            aspect = draggable.resize_keep_aspect_ratio,
          }, change_left, change_top, change_right, change_bottom, widget_privates[draggable].resize_handle_index)

          draggable.x = resize_start_x + change_left
          draggable.y = resize_start_y + change_top
          draggable.width = resize_start_width - change_left + change_right
          draggable.height = resize_start_height - change_top + change_bottom

          -- Recalculate the values
          local resize_handles = calculate_handle_props(draggable, resize_handle_size)
          widget_privates[draggable].resize_handle = resize_handles[widget_privates[draggable].resize_handle_index]
          local has_moved = resize_last_width_fired ~= draggable.width or resize_last_height_fired ~= draggable.height
          if has_moved then
            fire_event(draggable, "resize", { handle_index = widget_privates[draggable].resize_handle_index })
            resize_last_width_fired = draggable.width
            resize_last_height_fired = draggable.height
          end
        end,
        drag_end = function(result)
          fire_event(draggable, "resize_end", { handle_index = widget_privates[draggable].resize_handle_index })
          widget_privates[draggable].resize_handle_index = nil
          resizing_draggable = nil
        end
      })
      if do_draw_resize_cursor then
        draw_resize_cursor(gui, resize_handle_hovered_draggable.handle_index, sx, sy)
      end
    end

    mouse_state.world_x, mouse_state.world_y = DEBUG_GetMouseWorld()

    if mouse_state.left_pressed then
      fire_global_event("mouse_down", {
        button = "left",
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y
      })
    end
    if mouse_state.right_pressed then
      fire_global_event("mouse_down", {
        button = "right",
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y
      })
    end
    if mouse_state.left_up then
      fire_global_event("mouse_up", {
        button = "left",
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y
      })
    end
    if mouse_state.right_up then
      fire_global_event("mouse_up", {
        button = "right",
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y
      })
    end

    local movement_tolerance = 0.5
    if math.abs(mouse_state.dx) >= movement_tolerance or math.abs(mouse_state.dy) >= movement_tolerance then
      fire_global_event("mouse_move", {
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y,
        dx = mouse_state.dx,
        dy = mouse_state.dy
      })
    end
	end
end

return function(lib_path)
  path = lib_path
  return setmetatable({
    Widget = Widget,
    update = update,
    AddEventListener = AddEventListener,
    RemoveEventListener = RemoveEventListener
  }, {
    __index = function(self, key)
      return ({
        screen_x = mouse_state.sx,
        screen_y = mouse_state.sy,
        world_x = mouse_state.world_x,
        world_y = mouse_state.world_y,
        dx = mouse_state.dx,
        dy = mouse_state.dy,
        left_down = mouse_state.left_down,
        right_down = mouse_state.right_down
      })[key]
    end,
  })
end
