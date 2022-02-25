local function clamp(value, min, max)
	value = math.max(value, min)
	value = math.min(value, max)
	return value
end

-- Returns the value if it's not nil, otherwise returns val_if_nan
local function safe_divide(val, val_if_nan)
  local is_nan = val ~= val
  return is_nan and val_if_nan or val
end

-- float equals
local function feq(v1, v2)
  return math.abs(v1 - v2) < 0.001
end

local function sign(num)
  return num >= 0 and 1 or -1
end

return function(props, change_left, change_top, change_right, change_bottom, corner, test)
  local function print(...)
    if test then
      _G.print(...)
    end
  end
  props.min_width = props.min_width or 1
  props.min_height = props.min_height or 1
  props.max_width = props.max_width or 999999
  props.max_height = props.max_height or 999999
  props.symmetrical = not not props.symmetrical
  props.constraints = props.constraints or {}
  props.constraints.left = props.constraints.left or -999999
  props.constraints.top = props.constraints.top or -999999
  props.constraints.right = props.constraints.right or 999999
  props.constraints.bottom = props.constraints.bottom or 999999

  -- Constrain to boundary constraints
  -- local change_left_min = props.constraints.left - props.x
  -- local change_top_min = props.constraints.top - props.y
  -- local change_right_max = props.constraints.right - (props.x + props.width)
  -- local change_bottom_max = props.constraints.bottom - (props.y + props.height)

  -- Constrain to max sizes
  local change_left_min = props.width - props.max_width
  local change_top_min = props.height - props.max_height
  local change_right_max = props.max_width - props.width
  local change_bottom_max = props.max_height - props.height

  -- Constrain to min sizes
  local change_left_max = props.width - props.min_width
  local change_top_max = props.height - props.min_height
  local change_right_min = props.min_width - props.width
  local change_bottom_min = props.min_height - props.height

  if props.symmetrical then
    change_left_max = change_left_max / 2
    change_top_max = change_top_max / 2
    change_right_min = change_right_min / 2
    change_bottom_min = change_bottom_min / 2
    change_left_min = change_left_min / 2
    change_top_min = change_top_min / 2
    change_right_max = change_right_max / 2
    change_bottom_max = change_bottom_max / 2
  end

  local min_scale_left = (props.width - change_left_max) / props.width
  local max_scale_left = (props.width - change_left_min) / props.width
  local min_scale_right = (props.width + change_right_min) / props.width
  local max_scale_right = (props.width + change_right_max) / props.width
  local min_scale_top = (props.height - change_top_max) / props.height
  local max_scale_top = (props.height - change_top_min) / props.height
  local min_scale_bottom = (props.height + change_bottom_min) / props.height
  local max_scale_bottom = (props.height + change_bottom_max) / props.height

  local aspect_ratio = props.width / props.height
  local origin_of_scaling_x, origin_of_scaling_y = props.width / 2, props.height / 2

  if corner == 1 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = props.height
  elseif corner == 2 then
    origin_of_scaling_x = props.width / 2
    origin_of_scaling_y = props.height
  elseif corner == 3 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = props.height
  elseif corner == 4 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = props.height / 2
  elseif corner == 5 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = 0
  elseif corner == 6 then
    origin_of_scaling_x = props.width / 2
    origin_of_scaling_y = 0
  elseif corner == 7 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = 0
  elseif corner == 8 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = props.height / 2
  end

  local function get_new_width(change_left, change_right)
    return props.width - change_left + change_right
  end

  local function get_new_height(change_top, change_bottom)
    return props.height - change_top + change_bottom
  end

  local desired_scale_x = get_new_width(change_left, change_right) / props.width
  local desired_scale_y = get_new_height(change_top, change_bottom) / props.height

  -- Determine which scales need to be taken into account
  -- Get min and max scales of all into account taken scales
  -- Clamp desired scale between those min maxes
  local secondary = { left = false, top = false, right = false, bottom = false }
  local resize_left = corner == 1 or corner == 8 or corner == 7
  local resize_top = corner == 1 or corner == 2 or corner == 3
  local resize_right = corner == 3 or corner == 4 or corner == 5
  local resize_bottom = corner == 5 or corner == 6 or corner == 7

  if resize_left then
    if props.symmetrical then
      secondary.right = true
    end
    if props.aspect and not resize_top and not resize_bottom then
      secondary.top = true
      secondary.bottom = true
    end
  end

  if resize_top then
    if props.symmetrical then
      secondary.bottom = true
    end
    if props.aspect and not resize_left and not resize_right then
      secondary.left = true
      secondary.right = true
    end
  end

  if resize_right then
    if props.symmetrical then
      secondary.left = true
    end
    if props.aspect and not resize_top and not resize_bottom then
      secondary.top = true
      secondary.bottom = true
    end
  end

  if resize_bottom then
    if props.symmetrical then
      secondary.top = true
    end
    if props.aspect and not resize_left and not resize_right then
      secondary.left = true
      secondary.right = true
    end
  end

  if resize_left or resize_right then
    if secondary.top then
      desired_scale_x = math.min(desired_scale_x, max_scale_top)
    end
    if secondary.bottom then
      desired_scale_x = math.min(desired_scale_x, max_scale_bottom)
    end
  end

  if resize_top or resize_bottom then
    if secondary.left then
      desired_scale_y = math.min(desired_scale_y, max_scale_left)
    end
    if secondary.right then
      desired_scale_y = math.min(desired_scale_y, max_scale_right)
    end
  end

  if resize_left then
    desired_scale_x = clamp(desired_scale_x, min_scale_left, max_scale_left)
    desired_scale_x = math.max(desired_scale_x, 0)
  end

  if resize_top then
    desired_scale_y = clamp(desired_scale_y, min_scale_top, max_scale_top)
    desired_scale_y = math.max(desired_scale_y, 0)
  end

  if resize_right then
    desired_scale_x = clamp(desired_scale_x, min_scale_right, max_scale_right)
    desired_scale_x = math.max(desired_scale_x, 0)
  end

  if resize_bottom then
    desired_scale_y = clamp(desired_scale_y, min_scale_bottom, max_scale_bottom)
    desired_scale_y = math.max(desired_scale_y, 0)
  end

  if secondary.left then
    if props.symmetrical then
      max_scale_left = (max_scale_left - 1) * 2 + 1
    end
    desired_scale_x = clamp(desired_scale_x, min_scale_left, max_scale_left)
  end
  if secondary.right then
    if props.symmetrical then
      max_scale_right = (max_scale_right - 1) * 2 + 1
    end
    desired_scale_x = clamp(desired_scale_x, min_scale_right, max_scale_right)
  end
  if secondary.top then
    if props.symmetrical then
      max_scale_top = (max_scale_top - 1) * 2 + 1
    end
    desired_scale_y = clamp(desired_scale_y, min_scale_top, max_scale_top)
  end
  if secondary.bottom then
    if props.symmetrical then
      max_scale_bottom = (max_scale_bottom - 1) * 2 + 1
    end
    desired_scale_y = clamp(desired_scale_y, min_scale_bottom, max_scale_bottom)
  end

  local scale_x_percent = origin_of_scaling_x / props.width
  local scale_y_percent = origin_of_scaling_y / props.height

  local symmetry_multiplier = 1
  if props.symmetrical then
    scale_x_percent = 0.5
    scale_y_percent = 0.5
    symmetry_multiplier = 2
  end

  if props.aspect then
    local scale = 1
    if corner % 2 == 1 then
      scale = math.max(desired_scale_y, desired_scale_x)
    elseif corner == 2 or corner == 6 then
      scale = desired_scale_y
    elseif corner == 8 or corner == 4 then
      scale = desired_scale_x
    end
    if secondary.left then
      local s = max_scale_left
      if secondary.right then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_left, s)
    end
    if secondary.right then
      local s = max_scale_right
      if secondary.left then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_right, s)
    end
    if secondary.top then
      local s = max_scale_top
      if secondary.bottom then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_top, s)
    end
    if secondary.bottom then
      local s = max_scale_bottom
      if secondary.top then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_bottom, s)
    end

    if resize_left then
      local s = max_scale_left
      if secondary.right then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_left, s)
    end
    if resize_top then
      local s = max_scale_top
      if secondary.bottom then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_top, s)
    end
    if resize_right then
      local s = max_scale_right
      if secondary.left then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_right, s)
    end
    if resize_bottom then
      local s = max_scale_bottom
      if secondary.top then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_bottom, s)
    end

    desired_scale_x = scale
    desired_scale_y = scale
  end

  change_left = scale_x_percent * props.width * (1 - desired_scale_x)
  change_top = scale_y_percent * props.height * (1 - desired_scale_y)
  change_right = (1 - scale_x_percent) * -props.width * (1 - desired_scale_x)
  change_bottom = (1 - scale_y_percent) * -props.height * (1 - desired_scale_y)

  change_left = change_left * symmetry_multiplier
  change_top = change_top * symmetry_multiplier
  change_right = change_right * symmetry_multiplier
  change_bottom = change_bottom * symmetry_multiplier

  -- Now handle outside constraints

  -- Calculate by how much we overshot the constraints, then shrink all related sides equally
  local overshoot_left = math.max(0, props.constraints.left - (props.x + change_left))
  local overshoot_top = math.max(0, props.constraints.top - (props.y + change_top))
  local overshoot_right = math.max(0, (props.x + props.width + change_right) - props.constraints.right)
  local overshoot_bottom = math.max(0, (props.y + props.height + change_bottom) - props.constraints.bottom)

  local function safe_division(val, value_if_nan)
    local is_nan = val ~= val
    return is_nan and value_if_nan or val
  end
  -- if this is 0.1 it means it overshoots by 10% of its change_left
  local overshoot_scale_left = math.abs(safe_division(overshoot_left / change_left, 0))
  local overshoot_scale_top = math.abs(safe_division(overshoot_top / change_top, 0))
  local overshoot_scale_right = math.abs(safe_division(overshoot_right / change_right, 0))
  local overshoot_scale_bottom = math.abs(safe_division(overshoot_bottom / change_bottom, 0))

  -- Find the biggest overshoot scale and shrink all related sides by that
  local biggest_overshoot_scale = math.max(overshoot_scale_left, overshoot_scale_top, overshoot_scale_right, overshoot_scale_bottom)
  local scale = 0
  if props.aspect then
    scale = biggest_overshoot_scale
  end
  if resize_left or secondary.left then
    local scale = math.max(scale, overshoot_scale_left)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_left, overshoot_scale_right)
    end

    change_left = change_left * (1 - scale)
  end
  if resize_right or secondary.right then
    local scale = math.max(scale, overshoot_scale_right)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_left, overshoot_scale_right)
    end
    change_right = change_right * (1 - scale)
  end
  if resize_bottom or secondary.bottom then
    local scale = math.max(scale, overshoot_scale_bottom)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_top, overshoot_scale_bottom)
    end
    change_bottom = change_bottom * (1 - scale)
  end
  if resize_top or secondary.top then
    local scale = math.max(scale, overshoot_scale_top)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_top, overshoot_scale_bottom)
    end
    change_top = change_top * (1 - scale)
  end

  -- If very very close to the constraints, just "round up" to them and also adjust related sides by the same amount
  local left = props.x + change_left
  if left - props.constraints.left >= 0 and left - props.constraints.left < 0.00001 then
    local new_change_left = props.constraints.left - props.x
    change_right = change_right + (change_left - new_change_left)
    change_left = new_change_left
  end
  local top = props.y + change_top
  if top - props.constraints.top >= 0 and top - props.constraints.top < 0.00001 then
    local new_change_top = props.constraints.top - props.y
    change_bottom = change_bottom + (change_top - new_change_top)
    change_top = new_change_top
  end
  local right = props.x + props.width + change_right
  if props.constraints.right - right >= 0 and props.constraints.right - right < 0.00001 then
    local new_change_right = props.constraints.right - (props.x + props.width)
    change_left = change_left + (change_right - new_change_right)
    change_right = new_change_right
  end
  local bottom = props.y + props.height + change_bottom
  if props.constraints.bottom - bottom >= 0 and props.constraints.bottom - bottom < 0.00001 then
    local new_change_bottom = props.constraints.bottom - (props.y + props.height)
    change_top = change_top + (change_bottom - new_change_bottom)
    change_bottom = new_change_bottom
  end

  if props.quantization then
    local function round(v)
      if v > 0 then
        return math.floor(v)
      else
        return math.ceil(v)
      end
    end
    if props.aspect then
      -- This could probably be done better but I don't wanna think about it anymore...
      local new_change_left = round(change_left / props.quantization) * props.quantization
      local new_change_top = round(change_top / props.quantization) * props.quantization
      local new_change_right = round(change_right / props.quantization) * props.quantization
      local new_change_bottom = round(change_bottom / props.quantization) * props.quantization
      local scale_increase_left = (props.width - new_change_left) / props.width
      local scale_increase_top = (props.height - new_change_top) / props.height
      local scale_increase_right = (props.width + new_change_right) / props.width
      local scale_increase_bottom = (props.height + new_change_bottom) / props.height

      local new_scale = 1
      -- Take the dimension scale increase of the smaller size
      if props.width < props.height then
        local width_increase = -change_left + change_right
        local quantized_width_increase = round(width_increase / props.quantization) * props.quantization
        new_scale = (props.width + quantized_width_increase) / props.width
      else
        local height_increase = -change_top + change_bottom
        local quantized_height_increase = round(height_increase / props.quantization) * props.quantization
        new_scale = (props.height + quantized_height_increase) / props.height
      end
      
      change_left = scale_x_percent * props.width * (1 - new_scale)     
      change_top = scale_y_percent * props.height * (1 - new_scale)
      change_right = (1 - scale_x_percent) * -props.width * (1 - new_scale)
      change_bottom = (1 - scale_y_percent) * -props.height * (1 - new_scale)
    else
      change_left = round(change_left / props.quantization) * props.quantization
      change_top = round(change_top / props.quantization) * props.quantization
      change_right = round(change_right / props.quantization) * props.quantization
      change_bottom = round(change_bottom / props.quantization) * props.quantization
    end
  end

  return change_left, change_top, change_right, change_bottom
end
