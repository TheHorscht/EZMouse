return function(props, change_left, change_top, change_right, change_bottom)
  props.min_width = props.min_width or 0
  props.min_height = props.min_height or 0
  props.asym = not not props.asym

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

  -- Restrict shrinkage
  change_left = math.min(change_left, props.width)
  change_top = math.min(change_top, props.height)
  change_right = math.max(change_right, -props.width)
  change_bottom = math.max(change_bottom, -props.height)

  -- Restrict to min_ sizes
  change_left = math.min(change_left, props.width - props.min_width)
  change_right = math.max(change_right, -(props.width - props.min_width))
  change_top = math.min(change_top, props.height - props.min_height)
  change_bottom = math.max(change_bottom, -(props.height - props.min_height))

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

  return change_left, change_top, change_right, change_bottom
end
