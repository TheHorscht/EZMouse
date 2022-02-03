local function sign(num)
  return num >= 0 and 1 or -1
end

return function(props, change_left, change_top, change_right, change_bottom)
  props.min_width = props.min_width or 0
  props.min_height = props.min_height or 0
  props.asym = not not props.asym
  props.constraints = props.constraints or { left = -999999, top = -999999, right = 999999, bottom = 999999 }

  local function get_width()
    return props.width - change_left + change_right
  end

  -- Restrict expansion past contraints
  local function constrain_left()
    change_left = math.max(props.x + change_left, props.constraints.left) - props.x
  end
  local function constrain_top()
    change_top = math.max(props.y + change_top, props.constraints.top) - props.y
  end
  local function constrain_right()
    change_right = math.min(props.x + change_right, props.constraints.right - props.width) - props.x
  end
  local function constrain_bottom()
    change_bottom = math.min(props.y + change_bottom, props.constraints.bottom - props.height) - props.y
  end

  constrain_left()
  constrain_top()
  constrain_right()
  constrain_bottom()

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
      constrain_right()
      change_left = -change_right
    elseif math.abs(change_right) > 0 then
      change_left = -change_right
      constrain_left()
      change_right = -change_left
    end

    if math.abs(change_top) > 0 then
      change_bottom = -change_top
      constrain_bottom()
      change_top = -change_bottom
    elseif math.abs(change_bottom) > 0 then
      change_top = -change_bottom
      constrain_top()
      change_bottom = -change_top
    end
  end

  if props.aspect then
    local aspect_ratio = props.width / props.height
    if math.abs(change_left) > 0 then
      change_top = change_left / 2 / aspect_ratio
      change_bottom = -change_left / 2 / aspect_ratio
    elseif math.abs(change_right) > 0 then
      change_top = -change_right / 2 / aspect_ratio
      change_bottom = change_right / 2 / aspect_ratio
    elseif math.abs(change_top) > 0 then
      change_left = change_top / 2 * aspect_ratio
      change_right = -change_top / 2 * aspect_ratio
    elseif math.abs(change_bottom) > 0 then
      change_left = -change_bottom / 2 * aspect_ratio
      change_right = change_bottom / 2 * aspect_ratio
    end
  end

  return change_left, change_top, change_right, change_bottom
end
