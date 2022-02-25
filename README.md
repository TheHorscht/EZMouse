# EZMouse

A utility library for Noita which helps with getting the cursor position on the screen and provides a widget which can be used to make things drag- and resizable.

## Installation
Download a release, then place all the files into a subfolder of your mod and then initialize it by dofiling the main file, which will return an init function into which you pass the path to the folder you put the EZWand library in. This needs to be done once at (every) startup.
```lua
local EZMouse = dofile_once("mods/yourmod/lib/EZMouse/EZMouse.lua")("mods/yourmod/lib/EZMouse/")
```
## Usage
EZMouse needs a gui object (created using GuiCreate()) to work and has to have its update function called every frame.
You can either pass in an already existing one, or it will create one by itself. Also make sure to call EZMouse.update() AFTER GuiStartFrame().
After that, the library is ready to use. -- For instance you can get variousthe current world and screen position of the mouse cursor using:
### Mouse coordinates
- **number** `EZMouse.screen_x`
- **number** `EZMouse.screen_y`
- **number** `EZMouse.world_x`
- **number** `EZMouse.world_y`
- **number** `EZMouse.dx` Change in cursor position since last time update() was called
- **number** `EZMouse.dy`

These only work when there is no interactable GUI element under the cursor
- **boolean** `EZMouse.left_down` True if the left mouse button is currently down, false otherwise
- **boolean** `EZMouse.right_down` Same but with right button

### Event listeners
- **function** `EZMouse.AddEventListener(event_name : string, event_listener : function)` Register a function to be called when a certain even happens
- **function** `EZMouse.RemoveEventListener(event_name : string, event_listener : function)` Unregister a function previously registered

Events:
- **mouse_down** `Event args: { button : string = "left" | "right", screen_x : number, screen_y : number, world_x : number, world_y : number }`
- **mouse_up** `Event args: { button : string = "left" | "right", screen_x : number, screen_y : number, world_x : number, world_y : number }`
- **mouse_move** `Event args: { screen_x : number, screen_y : number, world_x : number, world_y : number, dx : number, dy : number }`

Example usage:
```lua
local mouse_move_event_listener = EZMouse.AddEventListener("mouse_move", function(event)
  print("Mouse has moved in the x direction by " .. event.dx)
end)
-- Some time later
EZMouse.RemoveEventListener("mouse_move", mouse_move_event_listener)
```

## Draggable Widget
The main reason to use EZMouse would be for its draggable/resizable widget.
It merely provides an invisible area on the screen which catches and reacts to mouse events. You would only use it to get the position and size, that you then use to draw your GUI at that position and size.

Here's how to create a widget:
```lua
local widget = EZMouse.Widget({
  x = 100,
  y = 50,
  -- Z index, higher = further in the back, widgets in the front will block mouse events for widgets in the back
  z = 1,
  min_width = 25, -- Can't be resized smalled than that
  width = 50,
  max_width = 100, -- Can't be resized bigger than that
  min_height = 25,
  height = 50,
  max_height = 100,
  resizable = false,
  draggable = false,
  enabled = false, -- If disabled will not be interactable at all
  drag_anchor = "center", -- Either "center" or nil, defines where it should be dragged from
  resize_granularity = 10, -- Makes resizing only happen in increments of 10
  resize_symmetrical = true, -- Will resize opposite sides too if enabled
  resize_keep_aspect_ratio = true, -- Keeps aspect ratio when resizing
  constraints = { left = 0, top = 0, right = 400, bottom = 400 } -- Defines a box past which it can neither be moved nor resized
})
```
Widgets also have events you can listen to of their own. To register one, don't forget to use `:` syntax instead of `.` like for the global events.
```lua
widget:AddEventListener("drag", function(self, event)
  print("Widget was moved by " .. event.dx, .. ", " .. event.dy)
end)
widget:AddEventListener("drag_end", function(self, event)
  -- Save new position in mod settings when done dragging
  ModSettingSet("yourmod.widget_x", self.x)
  ModSettingSet("yourmod.widget_y", self.y)
end)
```
Events:
- **drag** `{ dx : number, dy : number }`
- **drag_start** `{}`
- **drag_end** `{ start_x : number, start_y : number }`
- **resize** `{ handle_index : number }` handle_index is the handle/direction it was resized by, starting from 1 in the top left corner, going clockwise up to 8 for the left side
- **resize_start** `{ handle_index : number }`
- **resize_end** `{ handle_index : number }`

The widget will be invisible, so to visualize the widget for debug purposes, you can use:
```lua
widget:DebugDraw(gui, "red") -- color can be omitted which will then use "red" as the default. Other options are green and yellow.
```
