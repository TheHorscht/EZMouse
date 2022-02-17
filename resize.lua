-- float equals
local function feq(v1, v2)
  return math.abs(v1 - v2) < 0.001
end

local function sign(num)
  return num >= 0 and 1 or -1
end

return function(props, change_left, change_top, change_right, change_bottom, corner)
  props.min_width = props.min_width or 1
  props.min_height = props.min_height or 1
  props.max_width = props.max_width or 999999
  props.max_height = props.max_height or 999999
  props.asym = not not props.asym
  props.constraints = props.constraints or { left = -999999, top = -999999, right = 999999, bottom = 999999 }

  local resize_horizontally = false
  local resize_vertically = false
  -- Constrain to boundary constraints
  local change_left_min = props.constraints.left - props.x
  local change_top_min = props.constraints.top - props.y
  local change_right_max = props.constraints.right - (props.x + props.width)
  local change_bottom_max = props.constraints.bottom - (props.y + props.height)

  -- Constrain to max sizes
  change_left_min = math.max(change_left_min, props.width - props.max_width)
  change_top_min = math.max(change_top_min, props.height - props.max_height)
  change_right_max = math.min(change_right_max, props.max_width - props.width)
  change_bottom_max = math.min(change_bottom_max, props.max_height - props.height)

  -- Constrain to min sizes
  local change_left_max = props.width - props.min_width
  local change_top_max = props.height - props.min_height
  local change_right_min = props.min_width - props.width
  local change_bottom_min = props.min_height - props.height

  -- local min_scale_horizontal = props.min_width / props.width
  -- local min_scale_vertical = props.min_height / props.height
  local min_scale_left = (props.width - change_left_max) / props.width -- HEREEEEE
  local max_scale_left = (props.width - change_left_min) / props.width
  local min_scale_right = (props.width + change_right_min) / props.width -- HERE
  local max_scale_right = (props.width + change_right_max) / props.width
  local min_scale_top = (props.height - change_top_max) / props.height -- HERE
  local max_scale_top = (props.height - change_top_min) / props.height
  local min_scale_bottom = (props.height + change_bottom_min) / props.height -- HERE
  local max_scale_bottom = (props.height + change_bottom_max) / props.height

  local max_scale_horizontal = math.min(max_scale_left, max_scale_right)
  local max_scale_vertical = math.min(max_scale_top, max_scale_bottom)

  -- take smallest scale

  local aspect_ratio = props.width / props.height
  local origin_of_scaling_x, origin_of_scaling_y = props.width / 2, props.height / 2
  if corner % 2 == 1 then
    resize_horizontally = true
    resize_vertically = true
  elseif corner == 2 or corner == 6 then
    resize_vertically = true
  elseif corner == 4 or corner == 8 then
    resize_horizontally = true
  end

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
  -- scale_x = math.min(scale_x, max_scale_left)
  local scale_x = 1 -- math.min(desired_scale_x, max_scale_left)
  local scale_y = 1 -- math.min(desired_scale_y, max_scale_top)

  -- local scale_min = { min_scale_left, min_scale_top, min_scale_right, min_scale_bottom }
  -- local scale_max = { max_scale_left, max_scale_top, max_scale_right, max_scale_bottom }
  if corner == 1 or corner == 8 or corner == 7 then
    local min_scale_to_use = min_scale_left
    local max_scale_to_use = max_scale_left
    -- if props.aspect then
    --   min_scale_to_use = 
    -- end
    if props.asym then
      min_scale_to_use = math.min(min_scale_left, min_scale_right) * 1.75
      max_scale_to_use = math.min(max_scale_left, max_scale_right)
    end
    scale_x = math.max(desired_scale_x, min_scale_to_use)
    scale_x = math.min(scale_x, max_scale_to_use)
    scale_x = math.max(scale_x, 0)
    change_left = props.width * (1 - scale_x)
    if props.asym then
      change_right = props.width * -(1 - scale_x)
    end
  elseif corner == 3 or corner == 4 or corner == 5 then
    local min_scale_to_use = min_scale_right
    local max_scale_to_use = max_scale_right
    if props.asym then
      min_scale_to_use = math.min(min_scale_right, min_scale_left) * 1.75
      max_scale_to_use = math.min(max_scale_right, max_scale_left)
    end
    scale_x = math.max(desired_scale_x, min_scale_to_use)
    scale_x = math.min(scale_x, max_scale_to_use)
    scale_x = math.max(scale_x, 0)
    change_right = props.width * -(1 - scale_x)
    if props.asym then
      change_left = props.width * (1 - scale_x)
    end
  end
  if corner == 1 or corner == 2 or corner == 3 then
    local min_scale_to_use = min_scale_top
    local max_scale_to_use = max_scale_top
    if props.asym then
      min_scale_to_use = math.min(min_scale_top, min_scale_bottom) * 1.75
      max_scale_to_use = math.min(max_scale_top, max_scale_bottom)
    end
    scale_y = math.max(desired_scale_y, min_scale_to_use)
    scale_y = math.min(scale_y, max_scale_to_use)
    scale_y = math.max(scale_y, 0)
    change_top = props.height * (1 - scale_y)
    if props.asym then
      change_bottom = props.height * -(1 - scale_y)
    end
  elseif corner == 5 or corner == 6 or corner == 7 then
    local min_scale_to_use = min_scale_bottom
    local max_scale_to_use = max_scale_bottom
    if props.asym then
      min_scale_to_use = math.min(min_scale_bottom, min_scale_top) * 1.75
      max_scale_to_use = math.min(max_scale_bottom, max_scale_top)
    end
    scale_y = math.max(desired_scale_y, min_scale_to_use)
    scale_y = math.min(scale_y, max_scale_to_use)
    scale_y = math.max(scale_y, 0)
    change_bottom = props.height * -(1 - scale_y)
    if props.asym then
      change_top = props.height * (1 - scale_y)
    end
  end

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


  do return change_left, change_top, change_right, change_bottom end







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

  -- "Fix" aspect ratio for min sizes, if we use aspect mode and the aspect ratio for min sizes is different from width/height
  -- Better way would probably be to throw an error instead of silently fixing the "mistake"
  if props.aspect then
    local ratio = props.width / props.height
    if props.width > props.height then
      props.min_width = props.min_height * ratio
    else
      props.min_height = props.min_width / ratio
    end
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

  -- THis only restricts the INITIAL changes, not the ones made after aspect ratio scaling

  -- Restrict shrinkage to min_ sizes
  change_left = math.min(change_left, (props.width - props.min_width) / (props.asym and 2 or 1))
  change_right = math.max(change_right, -(props.width - props.min_width) / (props.asym and 2 or 1))
  change_top = math.min(change_top, (props.height - props.min_height) / (props.asym and 2 or 1))
  change_bottom = math.max(change_bottom, -(props.height - props.min_height) / (props.asym and 2 or 1))

  -- Restrict expansion to max_ sizes
  change_left = math.max(change_left, (props.width - props.max_width) / (props.asym and 2 or 1))
  change_right = math.min(change_right, -(props.width - props.max_width) / (props.asym and 2 or 1))
  change_top = math.max(change_top, (props.height - props.max_height) / (props.asym and 2 or 1))
  change_bottom = math.min(change_bottom, -(props.height - props.max_height) / (props.asym and 2 or 1))

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

      local new_width = get_width(change_left * new_scale, change_right * new_scale)
      local new_height = get_height(change_top * new_scale, change_bottom * new_scale)
      -- If it's smaller than 1 we need to scale up back to 1
      local min_width_constraint_scale = math.min(1, new_width / props.min_width)
      local min_height_constraint_scale = math.min(1, new_height / props.min_height)
      local min_size_constraint_scale = math.min(min_width_constraint_scale, min_height_constraint_scale)

      if is_nan(min_size_constraint_scale) then
        min_size_constraint_scale = 1
      end

      change_left = change_left * new_scale / min_size_constraint_scale
      change_top = change_top * new_scale / min_size_constraint_scale
      change_right = change_right * new_scale / min_size_constraint_scale
      change_bottom = change_bottom * new_scale / min_size_constraint_scale
    end
  end

  GlobalsSetValue("debug_value_1", change_left)
  GlobalsSetValue("debug_value_2", change_top)
  GlobalsSetValue("debug_value_3", change_right)
  GlobalsSetValue("debug_value_4", change_bottom)

  return change_left, change_top, change_right, change_bottom
end
