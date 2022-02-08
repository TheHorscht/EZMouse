-- float equals
local function feq(v1, v2)
  return math.abs(v1 - v2) < 0.001
end

local function sign(num)
  return num >= 0 and 1 or -1
end

return function(props, change_left, change_top, change_right, change_bottom, corner)
  props.min_width = props.min_width or 0
  props.min_height = props.min_height or 0
  props.asym = not not props.asym
  props.constraints = props.constraints or { left = -999999, top = -999999, right = 999999, bottom = 999999 }

  local change_left_min = props.constraints.left - props.x
  local change_top_min = props.constraints.top - props.y
  local change_right_max = props.constraints.right - (props.x + props.width)
  local change_bottom_max = props.constraints.bottom - (props.y + props.height)

  local function get_width(change_left, change_right)
    return props.width - change_left + change_right
  end

  local function get_height(change_top, change_bottom)
    return props.height - change_top + change_bottom
  end

  -- Restrict expansion past contraints
  local function constrain_left()
    return math.max(change_left_min, change_left)
  end
  local function constrain_top()
    return math.max(change_top_min, change_top)
  end
  local function constrain_right()
    return math.min(change_right_max, change_right)
  end
  local function constrain_bottom()
    return math.min(change_bottom_max, change_bottom)
  end

  change_left = constrain_left()
  change_top = constrain_top()
  change_right = constrain_right()
  change_bottom = constrain_bottom()

  if props.quantization then
    local function round(v)
      if v > 0 then
        return math.floor(v)
      else
        return math.ceil(v)
      end
    end
    change_left = round(change_left / props.quantization) * props.quantization
    change_top = round(change_top / props.quantization) * props.quantization
    change_right = round(change_right / props.quantization) * props.quantization
    change_bottom = round(change_bottom / props.quantization) * props.quantization
  end

  -- Restrict shrinkage to min_ sizes
  change_left = math.min(change_left, (props.width - props.min_width) / (props.asym and 2 or 1))
  change_right = math.max(change_right, -(props.width - props.min_width) / (props.asym and 2 or 1))
  change_top = math.min(change_top, (props.height - props.min_height) / (props.asym and 2 or 1))
  change_bottom = math.max(change_bottom, -(props.height - props.min_height) / (props.asym and 2 or 1))

  if props.asym then
    if math.abs(change_left) > 0 then
      change_right = -change_left
      change_right = constrain_right()
      change_left = -change_right
    elseif math.abs(change_right) > 0 then
      change_left = -change_right
      change_left = constrain_left()
      change_right = -change_left
    end

    if math.abs(change_top) > 0 then
      change_bottom = -change_top
      change_bottom = constrain_bottom()
      change_top = -change_bottom
    elseif math.abs(change_bottom) > 0 then
      change_top = -change_bottom
      change_top = constrain_top()
      change_bottom = -change_top
    end
  end

  if props.aspect then
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

    local scale_x = get_width(change_left, change_right) / props.width
    local scale_y = get_height(change_top, change_bottom) / props.height

    if scale_x ~= 1 or scale_y ~= 1 then
      local scale_x_percent, scale_y_percent = origin_of_scaling_x / props.width, origin_of_scaling_y / props.height
      local scale = 0

      if corner and corner % 2 == 1 then
        if math.abs(scale_x) > math.abs(scale_y) then
          scale = scale_x
        else
          scale = scale_y
        end
      else
        if scale_x ~= 1 then
          scale = scale_x
        else
          scale = scale_y
        end
      end

      change_left = scale_x_percent * props.width * (1 - scale)
      change_top = scale_y_percent * props.height * (1 - scale)
      change_right = (1 - scale_x_percent) * -props.width * (1 - scale)
      change_bottom = (1 - scale_y_percent) * -props.height * (1 - scale)

      local change_left_scaled = constrain_left() / change_left
      local change_top_scaled = constrain_top() / change_top
      local change_right_scaled = constrain_right() / change_right
      local change_bottom_scaled = constrain_bottom() / change_bottom

      local function is_nan(value)
        return value ~= value
      end

      if is_nan(change_left_scaled) then
        change_left_scaled = 1
      end
      if is_nan(change_top_scaled) then
        change_top_scaled = 1
      end
      if is_nan(change_right_scaled) then
        change_right_scaled = 1
      end
      if is_nan(change_bottom_scaled) then
        change_bottom_scaled = 1
      end

      local new_scale = math.min(change_left_scaled, change_top_scaled, change_right_scaled, change_bottom_scaled)

      change_left = change_left * new_scale
      change_top = change_top * new_scale
      change_right = change_right * new_scale
      change_bottom = change_bottom * new_scale
    end
  end

  return change_left, change_top, change_right, change_bottom
end
