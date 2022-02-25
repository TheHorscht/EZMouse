local update_draggable = dofile("resize.lua")

GlobalsSetValue = function() end

-- local function created_merged_table(t1, t2)
--   local t = {}
--   for k, v in pairs(t2) do
--     if type(v) == "table" then
--       merge_table(t1[k], v)
--     else
--       t1[k] = v
--     end
--   end
--   return t
-- end
local function count_table_keys(t)
  local num_keys = 0
  for k, v in pairs(t) do
    num_keys = num_keys + 1
  end
  return num_keys
end

local function created_merged_table(t1, t2)
  local t = {}
  for k, v in pairs(t1) do
    if t2[k] then
      if type(v) == "table" then
        t[k] = created_merged_table(v, t2[k])
      else
        t[k] = t2[k]
      end
    else
      if type(v) == "table" then
        t[k] = created_merged_table(v, {})
      else
        t[k] = v
      end
    end
  end
  return t
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end

local function calc_width(props, change_left, change_right)
  return props.width - change_left + change_right
end

local function calc_height(props, change_top, change_bottom)
  return props.height - change_top + change_bottom
end

local function calc_size(props, change_left, change_top, change_right, change_bottom)
  return calc_width(props, change_left, change_right), calc_height(props, change_top, change_bottom)
end

local function feq2(v1, v2)
  return math.abs(v1 - v2) < 0.001
end

-- float equals
local function feq(v1)
  return {
    value = v1,
    func = function(v2)
      return math.abs(v1 - v2) < 0.001
    end
  }
end

local function not_nan()
  return {
    value = "'not nan'",
    func = function(value)
      return not (value ~= value)
    end
  }
end

local function varg_to_string(...)
  local vargs = type(...) == "table" and ... or {...}
  local str = "("
  for i, v in ipairs(vargs) do
    if type(v) == "table" then
      if type(v.value) == "number" then
        str = str .. string.format("%.2f", v.value)
      else
        str = str .. string.format("%s", v.value)
      end
    else
      str = str .. string.format("%.2f", v)
    end
    if next(vargs, i) then
      str = str .. ", "
    end
  end
  str = str .. ")"
  return str
end

local function expect(...)
  local values = {...}
  local error_level = 2
  local info
  local out
  out = {
    error_level = function(level)
      error_level = level
      return out
    end,
    info = function(msg)
      info = msg
      return out
    end,
    to_be = function(...)
      local expectation = {...}
      local function throw_error()
        local error_message = ("Expected %s, got %s"):format(varg_to_string(expectation), varg_to_string(values))
        if info then
          error_message = "Info("..info..") " .. error_message
        end
        error(error_message, error_level + 1)
      end
      for i, v in ipairs(expectation) do
        if type(v) == "table" and v.func then
          if not v.func(values[i])  then
            throw_error()
          end
        elseif type(v) == "number" then
          if not feq2(v, values[i]) then
            throw_error()
          end
        elseif v ~= values[i] then
          throw_error()
        end
      end
    end
  }
  return out
end

local tests = {}
local SKIP_tests = {}
local ONLY_tests = {}

local function test(name, func)
  table.insert(tests, { name = name, func = func })
end
local function skip_test(name, func)
  table.insert(SKIP_tests, { name = name, func = func })
end
local function only_test(name, func)
  table.insert(ONLY_tests, { name = name, func = func })
end

test("Basic", function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
  }
  expect(update_draggable(props, -20, 0, 0, 0, 8)).to_be(-20, 0, 0, 0)
  expect(update_draggable(props, 0, -20, 0, 0, 2)).to_be(0, -20, 0, 0)
  expect(update_draggable(props, 0, 0, 20, 0, 4)).to_be(0, 0, 20, 0)
  expect(update_draggable(props, 0, 0, 0, 20, 6)).to_be(0, 0, 0, 20)
end)

test("Can't resize past constraints", function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 30, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, -51, 0, 0, 0, 8)).to_be(-20, 0, 0, 0)
  expect(update_draggable(props, 0, -52, 0, 0, 2)).to_be(0, -20, 0, 0)
  expect(update_draggable(props, 0, 0, 53, 0, 4)).to_be(0, 0, 30, 0)
  expect(update_draggable(props, 0, 0, 0, 54, 6)).to_be(0, 0, 0, 30)
  local props = {
    x = 0, y = 0,
    width = 20, height = 20,
    constraints = { left = 0, top = 30, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, -20, 0, 0, 0, 8)).to_be(0, 0, 0, 0)
end)

test("Resizer not moving past the opposite side", function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 0, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, 200, 0, 0, 0, 8)).to_be(19, 0, 0, 0)
  expect(update_draggable(props, 0, 200, 0, 0, 2)).to_be(0, 19, 0, 0)
  expect(update_draggable(props, 0, 0, -200, 0, 4)).to_be(0, 0, -19, 0)
  expect(update_draggable(props, 0, 0, 0, -200, 6)).to_be(0, 0, 0, -19)
end)

test("Can't resize smaller than min size", function()
  local props2 = {
    x = 100, y = 50,
    width = 30, height = 80,
    min_width = 20, min_height = 70,
    constraints = { left = 50, top = 0, right = 200, bottom = 200 }
  }
  expect(update_draggable(props2, 20, 0, 0, 0, 8)).to_be(feq(10), feq(0), feq(0), feq(0))
  expect(update_draggable(props2, 0, 20, 0, 0, 2)).to_be(feq(0), feq(10), feq(0), feq(0))
  expect(update_draggable(props2, 0, 0, -20, 0, 4)).to_be(feq(0), feq(0), feq(-10), feq(0))
  expect(update_draggable(props2, 0, 0, 0, -20, 6)).to_be(feq(0), feq(0), feq(0), feq(-10))
end)

test("Can't resize bigger than max size", function()
  local props2 = {
    x = 0, y = 0,
    width = 50, height = 50,
    max_width = 100, max_height = 100,
  }
  expect(update_draggable(props2, -200, 0, 0, 0, 8)).to_be(-50, 0, 0, 0)
  expect(update_draggable(props2, 0, -200, 0, 0, 2)).to_be(0, -50, 0, 0)
  expect(update_draggable(props2, 0, 0, 200, 0, 4)).to_be(0, 0, 50, 0)
  expect(update_draggable(props2, 0, 0, 0, 200, 6)).to_be(0, 0, 0, 50)
end)

test("(symmetrical) Resizes the opposite side (no constraints)", function()
  local props3 = {
    x = 100, y = 50,
    width = 50, height = 50,
    min_width = 10, min_height = 10,
    symmetrical = true,
    constraints = { left = 0, top = 0, right = 200, bottom = 200 }
  }
  expect(update_draggable(props3, -20, 0, 0, 0, 8)).to_be(-20, 0, 20, 0)
  expect(update_draggable(props3, 0, -20, 0, 0, 2)).to_be(0, -20, 0, 20)
  expect(update_draggable(props3, 0, 0, -20, 0, 4)).to_be(20, 0, -20, 0)
  expect(update_draggable(props3, 0, 0, 0, -20, 6)).to_be(0, 20, 0, -20)
  expect(update_draggable(props3, 20, 0, 0, 0, 8)).to_be(20, 0, -20, 0)
  expect(update_draggable(props3, 0, 20, 0, 0, 2)).to_be(0, 20, 0, -20)
  expect(update_draggable(props3, 0, 0, 20, 0, 4)).to_be(-20, 0, 20, 0)
  expect(update_draggable(props3, 0, 0, 0, 20, 6)).to_be(0, -20, 0, 20)
end)

test("(symmetrical) Shrinking stops at min_ sizes", function()
  local props = {
    symmetrical = true,
    x = 100, y = 100,
    width = 70, height = 70,
    min_width = 20, min_height = 20,
  }
  expect(update_draggable(props, 30, 0, 0, 0, 8)).to_be(25, 0, -25, 0)
  expect(update_draggable(props, 0, 30, 0, 0, 2)).to_be(0, 25, 0, -25)
  expect(update_draggable(props, 0, 0, -30, 0, 4)).to_be(25, 0, -25, 0)
  expect(update_draggable(props, 0, 0, 0, -30, 6)).to_be(0, 25, 0, -25)
end)

test("(symmetrical) Resizer stops when opposite side hits constraint", function()
  local props = {
    symmetrical = true,
    x = 100, y = 100,
    width = 50, height = 50,
    min_width = 20, min_height = 20,
    constraints = { left = 50, top = 50, right = 160, bottom = 200 }
  }
  expect(update_draggable(created_merged_table(props, { constraints = { left = 50, right = 160 }}), -100, 0, 0, 0, 8)).to_be(-10, 0, 10, 0)
  expect(update_draggable(created_merged_table(props, { constraints = { bottom = 170, top = 0 }}), 0, -100, 0, 0, 2)).to_be(0, -20, 0, 20)
  expect(update_draggable(created_merged_table(props, { constraints = { left = 80, right = 200 }}), 0, 0, 100, 0, 4)).to_be(-20, 0, 20, 0)
  expect(update_draggable(created_merged_table(props, { constraints = { bottom = 200, top = 90 }}), 0, 0, 0, 100, 6)).to_be(0, -10, 0, 10)
end)

test("(quant) Resizing gets quantized", function()
  local props = {
    quantization = 10,
    x = 0, y = 0,
    width = 100, height = 100,
  }
  for i=1, 2 do
    local sign = i == 1 and -1 or 1
    expect(update_draggable(props,  7 * sign, 0, 0, 0, 8)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 13 * sign, 0, 0, 0, 8)).to_be(10 * sign, 0, 0, 0)
    expect(update_draggable(props, 0,  7 * sign, 0, 0, 2)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 13 * sign, 0, 0, 2)).to_be(0, 10 * sign, 0, 0)
    expect(update_draggable(props, 0, 0,  7 * sign, 0, 4)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 0, 13 * sign, 0, 4)).to_be(0, 0, 10 * sign, 0)
    expect(update_draggable(props, 0, 0, 0,  7 * sign, 6)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 0, 0, 13 * sign, 6)).to_be(0, 0, 0, 10 * sign)
  end
end)

test("(quant) Hitting constraints respects quantization", function()
  local props = {
    quantization = 14,
    x = 100, y = 100,
    width = 50, height = 50,
    constraints = { left = 50, top = 50, right = 200, bottom = 200 }
  }
  expect(update_draggable(props, -70, 0, 0, 0, 8)).to_be(-42, 0, 0, 0)
  expect(update_draggable(props, 0, -70, 0, 0, 2)).to_be(0, -42, 0, 0)
  expect(update_draggable(props, 0, 0, 70, 0, 4)).to_be(0, 0, 42, 0)
  expect(update_draggable(props, 0, 0, 0, 70, 6)).to_be(0, 0, 0, 42)
end)

test("(quant) Width and height increase in multiples of quantization", function()
  local props = {
    quantization = 15,
    x = 0, y = 0,
    width = 100, height = 100,
  }
  for i=1, 2 do
    local function test(props, change_left, change_top, change_right, change_bottom, corner)
      local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom, corner)
      expect((calc_width(props, change_left, change_right) - props.width) % props.quantization).error_level(3).to_be(0)
      expect((calc_height(props, change_top, change_bottom) - props.height) % props.quantization).error_level(3).to_be(0)
    end
    local sign = i == 1 and -1 or 1
    test(props,  7 * sign, 0, 0, 0, 8)
    test(props, 13 * sign, 0, 0, 0, 8)
    test(props, 0,  7 * sign, 0, 0, 2)
    test(props, 0, 13 * sign, 0, 0, 2)
    test(props, 0, 0,  7 * sign, 0, 4)
    test(props, 0, 0, 13 * sign, 0, 4)
    test(props, 0, 0, 0,  7 * sign, 6)
    test(props, 0, 0, 0, 13 * sign, 6)
  end
end)

-- This should kind of be redundant because of the way more specific tests below, but...
-- it's probably better to have too many tests than too few
test("(aspect) Keeps aspect ratio when resizing", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 150,
    aspect = true,
  }
  local function resize(props, change_left, change_top, change_right, change_bottom, corner)
    local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom, corner)
    local new_width = calc_width(props, change_left, change_right)
    local new_height = calc_height(props, change_top, change_bottom)
    return new_width, new_height
  end
  expect(resize(props, -50, 0, 0, 0, 8)).to_be(100, 300)
  expect(resize(props, 0, -150, 0, 0, 2)).to_be(100, 300)
  expect(resize(props, 0, 0, 50, 0, 4)).to_be(100, 300)
  expect(resize(props, 0, 0, 0, 150, 6)).to_be(100, 300)
  expect(resize(props, 25, 0, 0, 0, 8)).to_be(25, 75)
  expect(resize(props, 0, 75, 0, 0, 2)).to_be(25, 75)
  expect(resize(props, 0, 0, -25, 0, 4)).to_be(25, 75)
  expect(resize(props, 0, 0, 0, -75, 6)).to_be(25, 75)
end)

test("(aspect) (L,R,U,D) Adjacent sides get resized equally", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 150,
    aspect = true,
  }
  for i=1, 2 do
    local sign = i == 1 and -1 or 1
    expect(update_draggable(props, sign * 30, 0, 0, 0, 8)).to_be(feq(sign * 30), feq(sign * 45), 0, feq(sign * -45))
    expect(update_draggable(props, 0, sign * 30, 0, 0, 2)).to_be(feq(sign * 5), feq(sign * 30), feq(sign * -5), 0)
    expect(update_draggable(props, 0, 0, sign * 30, 0, 4)).to_be(0, feq(sign * -45), feq(sign * 30), feq(sign * 45))
    expect(update_draggable(props, 0, 0, 0, sign * 30, 6)).to_be(feq(sign * -5), 0, feq(sign * 5), feq(sign * 30))
  end
end)

test("(aspect) Diagonal resizing", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 150,
    aspect = true,
  }
  local ratio = props.height / props.width
  -- The shorter side that gets resized should take precedence because it takes less absolute movement to scale it

  -- Top left corner
  expect(update_draggable(props, -10, -10, 0, 0, 1)).to_be(feq(-10),       feq(-10*ratio), 0, 0)
  expect(update_draggable(props,  10,  10, 0, 0, 1)).to_be(feq( 10/ratio), feq( 10),       0, 0)
  expect(update_draggable(props, -10,  10, 0, 0, 1)).to_be(feq(-10),       feq(-10*ratio), 0, 0)
  expect(update_draggable(props,  10, -10, 0, 0, 1)).to_be(feq(-10/ratio), feq(-10),       0, 0)
  expect(update_draggable(props, -10,   0, 0, 0, 1)).to_be(feq(-10),       feq(-10*ratio), 0, 0)
  expect(update_draggable(props,  10,   0, 0, 0, 1)).to_be(0, 0, 0, 0)
  expect(update_draggable(props,   0, -10, 0, 0, 1)).to_be(feq(-10/ratio), feq(-10),       0, 0)
  expect(update_draggable(props,   0,  10, 0, 0, 1)).to_be(0, 0, 0, 0)
  
  -- Top right corner
  expect(update_draggable(props, 0, -10, -10, 0, 3)).to_be(0, feq(-10),       feq( 10/ratio), 0)
  expect(update_draggable(props, 0,  10,  10, 0, 3)).to_be(0, feq(-10*ratio), feq( 10), 0)
  expect(update_draggable(props, 0, -10,  10, 0, 3)).to_be(0, feq(-10*ratio), feq( 10), 0)
  expect(update_draggable(props, 0,  10, -10, 0, 3)).to_be(0, feq( 10),       feq(-10/ratio), 0)
  expect(update_draggable(props, 0, -10,   0, 0, 3)).to_be(0, feq(-10),       feq( 10/ratio), 0)
  expect(update_draggable(props, 0,  10,   0, 0, 3)).to_be(0, 0, 0, 0)
  expect(update_draggable(props, 0,   0, -10, 0, 3)).to_be(0, 0, 0, 0)
  expect(update_draggable(props, 0,   0,  10, 0, 3)).to_be(0, feq(-10*ratio), feq( 10), 0)

  -- Bottom right corner
  expect(update_draggable(props, 0, 0, -10, -10, 5)).to_be(0, 0, feq(-10/ratio), feq(-10))
  expect(update_draggable(props, 0, 0,  10,  10, 5)).to_be(0, 0, feq( 10),       feq( 10*ratio))
  expect(update_draggable(props, 0, 0, -10,  10, 5)).to_be(0, 0, feq( 10/ratio), feq( 10))
  expect(update_draggable(props, 0, 0,  10, -10, 5)).to_be(0, 0, feq( 10),       feq( 10*ratio))
  expect(update_draggable(props, 0, 0, -10,   0, 5)).to_be(0, 0, 0, 0)
  expect(update_draggable(props, 0, 0,  10,   0, 5)).to_be(0, 0, feq( 10),       feq( 10*ratio))
  expect(update_draggable(props, 0, 0,   0, -10, 5)).to_be(0, 0, 0, 0)
  expect(update_draggable(props, 0, 0,   0,  10, 5)).to_be(0, 0, feq( 10/ratio), feq( 10))
  
  -- Bottom left corner
  expect(update_draggable(props, -10, 0, 0, -10, 7)).to_be(feq(-10), 0, 0, feq( 10*ratio))
  expect(update_draggable(props,  10, 0, 0,  10, 7)).to_be(feq(-10/ratio), 0, 0, feq(10))
  expect(update_draggable(props, -10, 0, 0,  10, 7)).to_be(feq(-10), 0, 0, feq( 10*ratio))
  expect(update_draggable(props,  10, 0, 0, -10, 7)).to_be(feq( 10/ratio), 0, 0, feq(-10))
  expect(update_draggable(props, -10, 0, 0,   0, 7)).to_be(feq(-10), 0, 0, feq( 10*ratio))
  expect(update_draggable(props,  10, 0, 0,   0, 7)).to_be(0, 0, 0, 0)
  expect(update_draggable(props,   0, 0, 0, -10, 7)).to_be(0, 0, 0, 0)
  expect(update_draggable(props,   0, 0, 0,  10, 7)).to_be(feq(-10/ratio), 0, 0, feq( 10))
end)

test("(aspect) Resizes based on the bigger size", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 100,
    aspect = true,
  }
  expect(update_draggable(props, 0, 0, -10, 0, 3)).to_be(0, 0, 0, 0)
end)

test("(aspect) Does not jump when resizing", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 100,
    aspect = true,
  }
  expect(update_draggable(props, 0, -42, -18, 0, 3)).to_be(0, feq(-42), feq(21), 0)
  expect(update_draggable(props, 0, -42, -22, 0, 3)).to_be(0, feq(-42), feq(21), 0)
end)

test("(aspect) Constraints work when secondary sides hit them", function()
  local props = {
    x = 50, y = 20,
    width = 50, height = 100,
    aspect = true,
    constraints = { left = 0, top = 0, right = 200, bottom = 175, }
  }
  expect(update_draggable(created_merged_table(props, { width = 50, height = 100 }), -40, 0, 0, 0, 8)).to_be(-20, -20, 0, 20)
  expect(update_draggable(created_merged_table(props, { width = 50, height = 100, constraints = { bottom = 200 } }), -30, 0, 0, 0, 8)).to_be(-20, -20, 0, 20)
  expect(update_draggable(created_merged_table(props, { width = 30, height = 100, constraints = { bottom = 200 } }), -30, 0, 0, 0, 8)).to_be(-12, -20, 0, 20)
  expect(update_draggable(created_merged_table(props, { x = 10, y = 50, width = 100, height = 50 }), 0, -100, 0, 0, 2)).to_be(-10, -10, 10, 0)
  local props2 = created_merged_table(props, { x = 150, y = 50, constraints = { bottom = 500 } })
  expect(update_draggable(props2, 0, -100, 0, 0, 2)).to_be(0, 0, 0, 0)
  local props3 = created_merged_table(props, { x = 100, y = 500, constraints = { bottom = 5000 } })
  local c = { left = 50, top = 50, right = 300, bottom = 300 }
  local props3 = { aspect = true, constraints = c,
    x = 225, y = 200, width = 50, height = 100,
  }
  expect(update_draggable(props3, 0, -200, 0, 0, 2)).to_be(-25, -100, 25, 0)
  local props4 = { aspect = true, constraints = c,
    x = 230, y = 250, width = 25, height = 50,
  }
  local l, t, r, b = update_draggable(props4, 0, -200, 0, 0, 2)
  local new_right_side_x = props4.x + props4.width + r
  expect(new_right_side_x).to_be(300)
  expect(update_draggable(props4, 0, 0, 25, 0, 5)).to_be(0, 0, 0, 0)
end)

test("(aspect) Constraints of secondary side work resizing diagonally", function()
  local props = {
    x = 10, y = 10,
    width = 50, height = 100,
    aspect = true,
    constraints = { left = 0, top = 0, right = 200, bottom = 175, }
  }
  expect(update_draggable(props, -10, 0, 0, 0, 1)).to_be(feq(-5), feq(-10), 0, 0)
  expect(update_draggable(props, 0, -10, 0, 0, 1)).to_be(feq(-5), feq(-10), 0, 0)
  -- TODO: More comprehensive testing...
end)

test("(aspect) Min sizes get respected when resizing", function()
  local props = {
    x = 10, y = 10,
    width = 50, height = 100,
    min_width = 25, min_height = 25,
    aspect = true,
  }
  expect(update_draggable(created_merged_table(props, { min_height = 25 }), 0, 100, 0, 0, 2)).to_be(feq(12.50), feq(50), feq(-12.50), 0)
  expect(update_draggable(created_merged_table(props, { min_height = 35 }), 0, 100, 0, 0, 2)).to_be(feq(12.50), feq(50), feq(-12.50), 0)
  
  local function test(props, change_left, change_top, change_right, change_bottom, resize_handle_index)
    local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom, resize_handle_index)
    expect(calc_width(props, change_left, change_right)).error_level(3).to_be(25)
    expect(calc_height(props, change_top, change_bottom)).error_level(3).to_be(50)
  end
  test(props, 100, 100, 0, 0, 1)
  test(props, 0, 100, 0, 0, 2)
  test(props, 0, 100, -100, 0, 3)
  test(props, 0, 0, -100, 0, 4)
  test(props, 0, 0, -100, -100, 5)
  test(props, 0, 0, 0, -100, 6)
  test(props, 100, 0, 0, -100, 7)
  test(props, 100, 0, 0, 0, 8)
end)

test("(all) Output is 0 when input is 0", function()
  local props = {
    x = 10, y = 10,
    -- width = 25, height = 50,
    width = 50, height = 50,
    min_width = 25, min_height = 25,
    max_width = 70, max_height = 70,
    aspect = true,
  }
  for i=1, 8 do
    expect(update_draggable(props, 0, 0, 0, 0, i)).info(i).to_be(0, 0, 0, 0)
  end
end)

test("(aspect) Max sizes get respected when resizing", function()
  local props = {
    x = 10, y = 10,
    width = 25, height = 50,
    max_width = 50, max_height = 100,
    aspect = true,
  }

  expect(update_draggable(created_merged_table(props, { max_width = 50 }), 0, -100, 0, 0, 2)).to_be(feq(-12.50), feq(-50), feq(12.50), 0)
  expect(update_draggable(created_merged_table(props, { max_width = 55 }), 0, -100, 0, 0, 2)).to_be(feq(-12.50), feq(-50), feq(12.50), 0)
  expect(update_draggable(created_merged_table(props, { max_width = 50 }), -100, 0, 0, 0, 8)).to_be(feq(-25.00), feq(-25), 0, feq(25.00))

  local proopy = created_merged_table(props, { max_width = 35, max_height = 70 })
  expect(calc_size(proopy, update_draggable(proopy, -100, 0, 0, 0, 8))).to_be(feq(35), feq(70))
  expect(update_draggable(created_merged_table(props, { max_width = 55, max_height = 110 }), -100, 0, 0, 0, 8)).to_be(feq(-30), feq(-30), 0, feq(30))

  local function test(props, change_left, change_top, change_right, change_bottom, resize_handle_index)
    local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom, resize_handle_index)
    expect(calc_width(props, change_left, change_right)).error_level(3).to_be(50)
    expect(calc_height(props, change_top, change_bottom)).error_level(3).to_be(100)
  end
  test(props, -100, -100, 0, 0, 1)
  test(props, 0, -100, 0, 0, 2)
  test(props, 0, -100, 100, 0, 3)
  test(props, 0, 0, 100, 0, 4)
  test(props, 0, 0, 100, 100, 5)
  test(props, 0, 0, 0, 100, 6)
  test(props, -100, 0, 0, 100, 7)
  test(props, -100, 0, 0, 0, 8)
end)

test("(aspect + quant) Keeps aspect ratio", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 100,
    aspect = true,
    quantization = 5
  }
  local function calculate_aspect_ratio(props, change_left, change_top, change_right, change_bottom)
    return calc_width(props, change_left, change_right) / calc_height(props, change_top, change_bottom)
  end
  for i=1, 10 do
    expect(calculate_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 2))).info(i).to_be(0.5)
    expect(calculate_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 1))).info(i).to_be(0.5)
    expect(calculate_aspect_ratio(props, update_draggable(props, -10*i, 0, 0, 0, 1))).info(i).to_be(0.5)
  end
end)

test("(aspect + quant) Width and height increase only in quant sizes", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 100,
    aspect = true,
    quantization = 5
  }
  local function get_aspect_ratio(props, change_left, change_top, change_right, change_bottom)
    return calc_width(props, change_left, change_right) % props.quantization, calc_height(props, change_top, change_bottom) % props.quantization
  end
  for i=1, 10 do
    expect(get_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 2))).info(i).to_be(0, 0)
    expect(get_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 1))).info(i).to_be(0, 0)
    expect(get_aspect_ratio(props, update_draggable(props, -10*i, 0, 0, 0, 1))).info(i).to_be(0, 0)
  end
  -- TODO: More comprehensive tests?...
end)

test("(symmetrical) Can't resize past max size", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 50,
    max_width = 100,
    symmetrical = true,
  }
  expect(update_draggable(props, -333, 0, 0, 0, 1)).to_be(-25, 0, 25, 0)
  expect(update_draggable(props, -333, 0, 0, 0, 8)).to_be(-25, 0, 25, 0)
  expect(update_draggable(props, 0, 0, 333, 0, 3)).to_be(-25, 0, 25, 0)
  expect(update_draggable(props, 0, 0, 333, 0, 4)).to_be(-25, 0, 25, 0)
end)

test("(aspect + quant + symmetrical) Works", function()
  local props = {
    x = 0, y = 0,
    width = 50, height = 100,
    aspect = true,
    symmetrical = true,
    quantization = 5
  }
  local function get_aspect_ratio(props, change_left, change_top, change_right, change_bottom)
    return calc_width(props, change_left, change_right) % props.quantization, calc_height(props, change_top, change_bottom) % props.quantization
  end
  for i=1, 10 do
    expect(get_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 2))).info(i).to_be(0, 0)
    expect(get_aspect_ratio(props, update_draggable(props, 0, -10*i, 0, 0, 1))).info(i).to_be(0, 0)
    expect(get_aspect_ratio(props, update_draggable(props, -10*i, 0, 0, 0, 1))).info(i).to_be(0, 0)
  end
  -- TODO: More comprehensive tests?...
  expect(update_draggable(props, -5, 0, 0, 0, 1)).to_be(-5, -10, 5, 10)
end)

test("(aspect + quant + symmetrical) Can't resize past max size", function()
  local props = {
    x = 0, y = 0,
    width = 55, height = 110,
    max_width = 60, max_height = 200,
    aspect = true,
    symmetrical = true,
    -- quantization = 5
  }
  -- expect(false).to_be(true)
  expect(update_draggable(props, -20, 0, 0, 0, 8)).to_be(-2.5, -5, 2.5, 5)
  expect(update_draggable(props, 0, -20, 0, 0, 2)).to_be(-2.5, -5, 2.5, 5)
  for i=1, 10 do
    expect(update_draggable(props, 0, -10*i, 0, 0, 2)).info(i).to_be(-2.5, -5, 2.5, 5)
    expect(update_draggable(props, 0, -10*i, 0, 0, 1)).info(i).to_be(-2.5, -5, 2.5, 5)
    expect(update_draggable(props, -10*i, 0, 0, 0, 1)).info(i).to_be(-2.5, -5, 2.5, 5)
  end
  -- TODO: More comprehensive tests?...
  
end)

test("When resizing corners and going over constraints, don't do the weird thing", function()
  local props = {
    x = 5, y = 10,
    width = 50, height = 100,
    constraints = { top = 0, left = 0 }
  }
  expect(update_draggable(props, -20, -20, 0, 0, 1)).to_be(-5, -10, 0, 0)
  -- TODO: More comprehensive tests?...
end)

test("(quant) Resize up to contraints, don't stop before hitting them when the gap is very very small (< 0.000001)", function()
  local props = {
    x = 52.50, y = 167.50,
    width = 35, min_width = 25, max_width = 100,
    height = 70, min_height = 50, max_height = 200,
    constraints = {
      left = 50,
      top = 50,
      right = 90,
      bottom = 300
    },
    aspect = true,
    quantization = 5,
  }

  -- update_draggable(props, 0, -73, 0, 0, 2, true)
  -- update_draggable(props, 0, -74, 0, 0, 2, true)
  -- update_draggable(props, 0, -75, 0, 0, 2, true)

  expect(update_draggable(props, 0, -74, 0, 0, 2, true)).to_be(-2.5, -10, 2.5, 0)
  expect(update_draggable(props, 0, -75, 0, 0, 2, true)).to_be(-2.5, -10, 2.5, 0)
  expect(update_draggable(props, 0, -76, 0, 0, 2)).to_be(-2.5, -10, 2.5, 0)
  expect(update_draggable(props, 0, -77, 0, 0, 2)).to_be(-2.5, -10, 2.5, 0)
  -- TODO: More comprehensive tests?...
end)

-- ########################
-- ##### END OF TESTS #####
-- ########################

if #ONLY_tests > 0 then
  print("\27[93mOnly testing:\27[0m")
  local passed_tests = {}
  local failed_tests = {}
  for i, test in ipairs(ONLY_tests) do
    local success, result = pcall(test.func)
    if not success then
      table.insert(failed_tests, { test_name = test.name, error_message = result })
    else
      table.insert(passed_tests, { test_name = test.name })
    end
  end
  if #passed_tests > 0 then
    print(("\27[92m%d/%d\27[0m test(s) passed."):format(#passed_tests, #ONLY_tests))
  end
  for i, test in ipairs(failed_tests) do
    print(("\27[31m(FAIL)\27[0m %s || %s"):format(test.test_name, test.error_message))
  end
else
  local passed_tests = {}
  local failed_tests = {}
  local num_skipped = 0
  for i, test in ipairs(SKIP_tests) do
    num_skipped = num_skipped + 1
  end
  
  for i, test in pairs(tests) do
    local success, result = pcall(test.func)
    if not success then
      table.insert(failed_tests, { test_name = test.name, error_message = result })
    else
      table.insert(passed_tests, { test_name = test.name })
    end
  end
  if #passed_tests > 0 then
    print(("\27[92m%d/%d\27[0m test(s) passed."):format(#passed_tests, #tests))
  end
  if num_skipped > 0 then
    print(("\27[93m%d\27[0m test(s) skipped."):format(num_skipped))
  end
  for i, test in ipairs(failed_tests) do
    print(("\27[31m(FAIL)\27[0m %s || %s"):format(test.test_name, test.error_message))
  end
end
