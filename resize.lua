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

  local function get_width(change_left, change_right)
    return props.width - change_left + change_right
  end

  local function get_height(change_top, change_bottom)
    return props.height - change_top + change_bottom
  end

  -- Restrict expansion past contraints
  local function constrain_left()
    return math.max(props.x + change_left, props.constraints.left) - props.x
  end
  local function constrain_top()
    return math.max(props.y + change_top, props.constraints.top) - props.y
  end
  local function constrain_right()
    return math.min(props.x + change_right, props.constraints.right - props.width) - props.x
  end
  local function constrain_bottom()
    return math.min(props.y + change_bottom, props.constraints.bottom - props.height) - props.y
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

      -- local change_left_after_constraint = constrain_left()
      -- local change_top_after_constraint = constrain_top()
      -- local change_right_after_constraint = constrain_right()
      -- local change_bottom_after_constraint = constrain_bottom()

      -- If the change is different after constraining, the value will be different than 0
      -- local scales_after_constraint = {
      --   (change_left - constrain_left()),
      --   (change_top - constrain_top()),
      --   (change_right - constrain_right()),
      --   (change_bottom - constrain_bottom()),
      -- }
      -- If left was constrained, also constrain right to the same value, etc
      GlobalsSetValue("debug_value_1", change_left)
      GlobalsSetValue("debug_value_2", change_top)
      GlobalsSetValue("debug_value_3", change_right)
      GlobalsSetValue("debug_value_4", change_bottom)
      local function was_left_constrained()
        return not feq(constrain_left(), change_left)
      end
      local function was_left_changed()
        return not feq(change_left, 0)
      end
      local function was_top_constrained()
        return not feq(constrain_top(), change_top)
      end
      local function was_top_changed()
        return not feq(change_top, 0)
      end
      local function was_right_constrained()
        return not feq(constrain_right(), change_right)
      end
      local function was_right_changed()
        return not feq(change_right, 0)
      end
      local function was_bottom_constrained()
        return not feq(constrain_bottom(), change_bottom)
      end
      local function was_bottom_changed()
        return not feq(change_bottom, 0)
      end
      if was_left_constrained() and was_right_changed() then
        change_left = constrain_left()
        change_right = -constrain_left()
      elseif was_right_constrained() and was_left_changed() then
        change_left = -constrain_right()
        change_right = constrain_right()
      end
      if was_top_constrained() and was_bottom_changed() then
        change_top = constrain_top()
        change_bottom = -constrain_top()
      elseif was_bottom_constrained() and was_top_changed() then
        change_top = -constrain_bottom()
        change_bottom = constrain_bottom()
      end

      -- NEW!!!
      if was_left_constrained() and was_top_changed() then
      end

      local scale_x = get_width(change_left, change_right) / props.width
      local scale_y = get_height(change_top, change_bottom) / props.height
      -- GlobalsSetValue("debug_value_3", scale_x)
      -- GlobalsSetValue("debug_value_4", scale_y)
      scale = math.min(scale_x, scale_y)
      change_left = scale_x_percent * props.width * (1 - scale)
      change_top = scale_y_percent * props.height * (1 - scale)
      change_right = (1 - scale_x_percent) * -props.width * (1 - scale)
      change_bottom = (1 - scale_y_percent) * -props.height * (1 - scale)
    end
  end

  return change_left, change_top, change_right, change_bottom
end
