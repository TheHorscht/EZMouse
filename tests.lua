-- local expect = dofile("unit_test.lua")
local function expect(...)
  local values = {...}
  return {
    to_be = function(...)
      local expectation = {...}
      for i, v in ipairs(expectation) do
        if v ~= values[i] then
          error(("Expected %.2f at [%d], got %.2f"):format(v, i, values[i]), 2)
        end
      end
    end
  }
end

local update_draggable = dofile("resize.lua")

local props = {
  x = 100, y = 50,
  width = 20, height = 80,
  constraints = { left = 85, top = 0, right = 200, bottom = 200 }
}

local tests = {}
-- Constraints
tests["Left constraint works moving left resizer left"] = function()
  expect(update_draggable(props, -200, 0, 0, 0)).to_be(-15, 0, 0, 0)
end
tests["Top constraint works moving top resizer up"] = function()
  expect(update_draggable(props, 0, -70, 0, 0)).to_be(0, -50, 0, 0)
end
tests["Right constraint works moving right resizer right"] = function()
  expect(update_draggable(props, 0, 0, 200, 0)).to_be(0, 0, 80, 0)
end
tests["Bottom constraint works moving bottom resizer down"] = function()
  expect(update_draggable(props, 0, 0, 0, 200)).to_be(0, 0, 0, 70)
end
-- Resizer not moving past the opposite side
tests["Left resizer doesn't move past right side when moving right"] = function()
  expect(update_draggable(props, 200, 0, 0, 0)).to_be(20, 0, 0, 0)
end
tests["Top resizer doesn't move past bottom side when moving down"] = function()
  expect(update_draggable(props, 0, 200, 0, 0)).to_be(0, 80, 0, 0)
end
tests["Right resizer doesn't move past left side when moving left"] = function()
  expect(update_draggable(props, 0, 0, -200, 0)).to_be(0, 0, -20, 0)
end
tests["Bottom resizer doesn't move past top side when moving up"] = function()
  expect(update_draggable(props, 0, 0, 0, -200)).to_be(0, 0, 0, -80)
end
-- min_ size
local props2 = {
  x = 100, y = 50,
  width = 30, height = 80,
  min_width = 20, min_height = 70,
  constraints = { left = 50, top = 0, right = 200, bottom = 200 }
}
tests["Left resizer stops when hitting min_width when moving right"] = function()
  expect(update_draggable(props2, 20, 0, 0, 0)).to_be(10, 0, 0, 0)
end
tests["Right resizer stops when hitting min_width when moving left"] = function()
  expect(update_draggable(props2, 0, 0, -20, 0)).to_be(0, 0, -10, 0)
end
tests["Top resizer stops when hitting min_height when moving down"] = function()
  expect(update_draggable(props2, 0, 20, 0, 0)).to_be(0, 10, 0, 0)
end
tests["Bottom resizer stops when hitting min_width when moving up"] = function()
  expect(update_draggable(props2, 0, 0, 0, -20)).to_be(0, 0, 0, -10)
end

for test_name, test_func in pairs(tests) do
  local success, result = pcall(test_func)
  if not success then
    print(test_name .. " failed:\n" .. result)
  end
end
