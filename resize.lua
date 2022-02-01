return function(props, change_left, change_top, change_right, change_bottom)
  props.min_width = props.min_width or 0
  props.min_height = props.min_height or 0
  -- Restrict expansion past contraints
  change_left = math.max(props.x + change_left, props.constraints.left) - props.x
  change_top = math.max(props.y + change_top, props.constraints.top) - props.y
  change_right = math.min(props.x + change_right, props.constraints.right - props.width) - props.x
  change_bottom = math.min(props.y + change_bottom, props.constraints.bottom - props.height) - props.y

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

  return change_left, change_top, change_right, change_bottom
end
