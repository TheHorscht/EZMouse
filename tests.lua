local update_draggable = dofile("resize.lua")

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

local tests = {}
local SKIP_tests = {}
local ONLY_tests = {}
tests["Can't resize past constraints"] = function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 30, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, -51, 0, 0, 0)).to_be(-20, 0, 0, 0)
  expect(update_draggable(props, 0, -52, 0, 0)).to_be(0, -20, 0, 0)
  expect(update_draggable(props, 0, 0, 53, 0)).to_be(0, 0, 30, 0)
  expect(update_draggable(props, 0, 0, 0, 54)).to_be(0, 0, 0, 30)
end

tests["Resizer not moving past the opposite side"] = function()
  local props = {
    x = 50, y = 50,
    width = 20, height = 20,
    constraints = { left = 30, top = 0, right = 100, bottom = 100 }
  }
  expect(update_draggable(props, 200, 0, 0, 0)).to_be(20, 0, 0, 0)
  expect(update_draggable(props, 0, 200, 0, 0)).to_be(0, 20, 0, 0)
  expect(update_draggable(props, 0, 0, -200, 0)).to_be(0, 0, -20, 0)
  expect(update_draggable(props, 0, 0, 0, -200)).to_be(0, 0, 0, -20)
end

tests["Can't resize smaller than min size"] = function()
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
end

tests["(asym) Resizes the opposite side (no constraints)"] = function()
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
end

tests["(asym) Shrinking stops at min_ sizes"] = function()
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
end

tests["(asym) Resizer stops when opposite side hits constraint"] = function()
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
end

if count_table_keys(ONLY_tests) > 0 then
  print("Only testing: ")
  for test_name, test_func in pairs(ONLY_tests) do
    local success, result = pcall(test_func)
    if not success then
      print(test_name .. " failed: " .. result)
    end
  end
else
  for test_name, test_func in pairs(SKIP_tests) do
    print("Skipped test: '" .. test_name .. "'")
  end
  
  for test_name, test_func in pairs(tests) do
    local success, result = pcall(test_func)
    if not success then
      print("\27[31m(FAIL)\27[0m - " .. test_name .. " failed: " .. result)
    else
      print("\27[92m(SUCCESS)\27[0m - " .. test_name)
    end
  end
end
