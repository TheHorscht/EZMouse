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

-- float equals
local function feq(v1)
  return {
    value = v1,
    func = function(v2)
      return math.abs(v1 - v2) < 0.001
    end
  }
end

local function varg_to_string(...)
  local vargs = type(...) == "table" and ... or {...}
  local str = "("
  for i, v in ipairs(vargs) do
    if type(v) == "table" then
      str = str .. string.format("%.2f", v.value)
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
  local out
  out = {
    error_level = function(level)
      error_level = level
      return out
    end,
    to_be = function(...)
      local expectation = {...}
      for i, v in ipairs(expectation) do
        if type(v) == "table" and v.func then
          if not v.func(values[i])  then
            error(("Expected %s, got %s"):format(varg_to_string(expectation), varg_to_string(values)), error_level)
          end
        elseif v ~= values[i] then
          error(("Expected %s, got %s"):format(varg_to_string(expectation), varg_to_string(values)), error_level)
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

test("Can't resize past constraints", function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 30, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, -51, 0, 0, 0)).to_be(-20, 0, 0, 0)
  expect(update_draggable(props, 0, -52, 0, 0)).to_be(0, -20, 0, 0)
  expect(update_draggable(props, 0, 0, 53, 0)).to_be(0, 0, 30, 0)
  expect(update_draggable(props, 0, 0, 0, 54)).to_be(0, 0, 0, 30)
end)

test("Resizer not moving past the opposite side", function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 0, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, 200, 0, 0, 0)).to_be(20, 0, 0, 0)
  expect(update_draggable(props, 0, 200, 0, 0)).to_be(0, 20, 0, 0)
  expect(update_draggable(props, 0, 0, -200, 0)).to_be(0, 0, -20, 0)
  expect(update_draggable(props, 0, 0, 0, -200)).to_be(0, 0, 0, -20)
end)

test("Can't resize smaller than min size", function()
  local props2 = {
    x = 100, y = 50,
    width = 30, height = 80,
    min_width = 20, min_height = 70,
    constraints = { left = 50, top = 0, right = 200, bottom = 200 }
  }
  expect(update_draggable(props2, 20, 0, 0, 0)).to_be(10, 0, 0, 0)
  expect(update_draggable(props2, 0, 0, -20, 0)).to_be(0, 0, -10, 0)
  expect(update_draggable(props2, 0, 20, 0, 0)).to_be(0, 10, 0, 0)
  expect(update_draggable(props2, 0, 0, 0, -20)).to_be(0, 0, 0, -10)
end)

test("(asym) Resizes the opposite side (no constraints)", function()
  local props3 = {
    x = 100, y = 50,
    width = 50, height = 50,
    min_width = 10, min_height = 10,
    asym = true,
    constraints = { left = 0, top = 0, right = 200, bottom = 200 }
  }
  expect(update_draggable(props3, -20, 0, 0, 0)).to_be(-20, 0, 20, 0)
  expect(update_draggable(props3, 0, -20, 0, 0)).to_be(0, -20, 0, 20)
  expect(update_draggable(props3, 0, 0, -20, 0)).to_be(20, 0, -20, 0)
  expect(update_draggable(props3, 0, 0, 0, -20)).to_be(0, 20, 0, -20)
  expect(update_draggable(props3, 20, 0, 0, 0)).to_be(20, 0, -20, 0)
  expect(update_draggable(props3, 0, 20, 0, 0)).to_be(0, 20, 0, -20)
  expect(update_draggable(props3, 0, 0, 20, 0)).to_be(-20, 0, 20, 0)
  expect(update_draggable(props3, 0, 0, 0, 20)).to_be(0, -20, 0, 20)
end)

test("(asym) Shrinking stops at min_ sizes", function()
  local props = {
    asym = true,
    x = 100, y = 100,
    width = 50, height = 50,
    min_width = 20, min_height = 20,
  }
  expect(update_draggable(props, 30, 0, 0, 0)).to_be(15, 0, -15, 0)
  expect(update_draggable(props, 0, 0, -30, 0)).to_be(15, 0, -15, 0)
  expect(update_draggable(props, 0, 30, 0, 0)).to_be(0, 15, 0, -15)
  expect(update_draggable(props, 0, 0, 0, -30)).to_be(0, 15, 0, -15)
end)

test("(asym) Resizer stops when opposite side hits constraint", function()
  local props = {
    asym = true,
    x = 100, y = 100,
    width = 50, height = 50,
    min_width = 20, min_height = 20,
    constraints = { left = 50, top = 50, right = 160, bottom = 200 }
  }
  expect(update_draggable(created_merged_table(props, { constraints = { left = 50, right = 160 }}), -100, 0, 0, 0)).to_be(-10, 0, 10, 0)
  expect(update_draggable(created_merged_table(props, { constraints = { left = 80, right = 200 }}), 0, 0, 100, 0)).to_be(-20, 0, 20, 0)
  expect(update_draggable(created_merged_table(props, { constraints = { bottom = 170, top = 0 }}), 0, -100, 0, 0)).to_be(0, -20, 0, 20)
  expect(update_draggable(created_merged_table(props, { constraints = { bottom = 200, top = 90 }}), 0, 0, 0, 100)).to_be(0, -10, 0, 10)
end)

test("(quant) Resizing gets quantized", function()
  local props = {
    quantization = 10,
    x = 0, y = 0,
    width = 100, height = 100,
  }
  for i=1, 2 do
    local sign = i == 1 and -1 or 1
    expect(update_draggable(props,  7 * sign, 0, 0, 0)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 13 * sign, 0, 0, 0)).to_be(10 * sign, 0, 0, 0)
    expect(update_draggable(props, 0,  7 * sign, 0, 0)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 13 * sign, 0, 0)).to_be(0, 10 * sign, 0, 0)
    expect(update_draggable(props, 0, 0,  7 * sign, 0)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 0, 13 * sign, 0)).to_be(0, 0, 10 * sign, 0)
    expect(update_draggable(props, 0, 0, 0,  7 * sign)).to_be(0, 0, 0, 0)
    expect(update_draggable(props, 0, 0, 0, 13 * sign)).to_be(0, 0, 0, 10 * sign)
  end
end)

test("(quant) Hitting constraints respects quantization", function()
  local props = {
    quantization = 14,
    x = 100, y = 100,
    width = 50, height = 50,
    constraints = { left = 50, top = 50, right = 200, bottom = 200 }
  }
  expect(update_draggable(props, -70, 0, 0, 0)).to_be(-42, 0, 0, 0)
  expect(update_draggable(props, 0, -70, 0, 0)).to_be(0, -42, 0, 0)
  expect(update_draggable(props, 0, 0, 70, 0)).to_be(0, 0, 42, 0)
  expect(update_draggable(props, 0, 0, 0, 70)).to_be(0, 0, 0, 42)
end)

test("(quant) Width and height increase in multiples of quantization", function()
  local props = {
    quantization = 15,
    x = 0, y = 0,
    width = 100, height = 100,
  }
  for i=1, 2 do
    local function test(props, change_left, change_top, change_right, change_bottom)
      local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom)
      expect((calc_width(props, change_left, change_right) - props.width) % props.quantization).error_level(3).to_be(0)
      expect((calc_height(props, change_top, change_bottom) - props.height) % props.quantization).error_level(3).to_be(0)
    end
    local sign = i == 1 and -1 or 1
    test(props,  7 * sign, 0, 0, 0)
    test(props, 13 * sign, 0, 0, 0)
    test(props, 0,  7 * sign, 0, 0)
    test(props, 0, 13 * sign, 0, 0)
    test(props, 0, 0,  7 * sign, 0)
    test(props, 0, 0, 13 * sign, 0)
    test(props, 0, 0, 0,  7 * sign)
    test(props, 0, 0, 0, 13 * sign)
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
  local function resize(props, change_left, change_top, change_right, change_bottom)
    local change_left, change_top, change_right, change_bottom = update_draggable(props, change_left, change_top, change_right, change_bottom)
    local new_width = calc_width(props, change_left, change_right)
    local new_height = calc_height(props, change_top, change_bottom)
    return new_width, new_height
  end
  expect(resize(props, -50, 0, 0, 0)).to_be(100, 300)
  expect(resize(props, 0, -150, 0, 0)).to_be(100, 300)
  expect(resize(props, 0, 0, 50, 0)).to_be(100, 300)
  expect(resize(props, 0, 0, 0, 150)).to_be(100, 300)
  expect(resize(props, 25, 0, 0, 0)).to_be(25, 75)
  expect(resize(props, 0, 75, 0, 0)).to_be(25, 75)
  expect(resize(props, 0, 0, -25, 0)).to_be(25, 75)
  expect(resize(props, 0, 0, 0, -75)).to_be(25, 75)
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
  expect(update_draggable(props, 0, 0, 0, 0)).to_be(0, 0, 0, 0)
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
    x = 50, y = 50,
    width = 50, height = 100,
    aspect = true,
    constraints = { left = 0, top = 0, right = 200, bottom = 175, }
  }
  expect(update_draggable(created_merged_table(props, { width = 50, height = 100 }), -25, 0, 0, 0, 8)).to_be(-25, -25, 0, 25)
  expect(update_draggable(created_merged_table(props, { width = 100, height = 50 }), 0, -100, 0, 0, 2)).to_be(-50, -50, 50, 0)
  -- TODO: More comprehensive testing...
end)

test("(aspect) Constraints work resizing diagonally", function()
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
