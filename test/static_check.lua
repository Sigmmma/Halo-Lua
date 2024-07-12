-- Command-line script that statically checks a script for errors

--------------------
-- Script helpers --
--------------------

local test_count = 0
local test_failures = 0

---Very basic test function.
---If this gets any more complicated, probably just require busted.
---@param condition any
---@param name string
---@param message string?
function Test(condition, name, message)
	test_count = test_count + 1

	if condition then
		print("[pass] " .. name)
	else
		test_failures = test_failures + 1
		local output = "[FAIL] " .. name
		if message then
			output = output .. ": " .. message
		end
		print(output)
	end
end

-- Shamelessly ripped off from https://stackoverflow.com/a/7925115
function GetKeyForValue(table, value)
	for k,v in pairs(table) do
	  if v==value then return k end
	end
	return nil
end

-- *Unreal* that this isn't built-in.
function TableSize(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

-------------------
-- Script "main" --
-------------------

SCRIPT = arg[1]

if not SCRIPT then
	print(string.format("Usage: lua %s <script_to_check>", arg[0]))
	os.exit(0)
end

-- Load SAPP mocks so the target script can call them
dofile("./mock/sapp_mock_api.lua")
dofile("./mock/sapp_mock_game_state.lua")

print("Checking " .. SCRIPT)

-- All globals in the target script should now be available here.
-- NOTE: syntax errors are caught with a runtime error here.
dofile(SCRIPT)
Test(true, "Syntax check")

Test(_G["OnScriptLoad"], "Defines global function 'OnScriptLoad'")
Test(_G["OnScriptUnload"], "Defines global function 'OnScriptUnload'")

-- Simulate SAPP loading the target script.
-- NOTE: invalid callback table names are caught with a runtime error here.
OnScriptLoad()

Test(api_version, "Defines global value 'api_version'")

if TableSize(SAPPMock.callbacks) > 0 then
	Test(true, "Callback table names are valid")
end

for cb_index, func_name in pairs(SAPPMock.callbacks) do
	local cb_name = GetKeyForValue(cb, cb_index)
	Test(
		_G[func_name] ~= nil,
		string.format("Callback %s function exists", cb_name),
		string.format("Cannot find function named '%s'", func_name)
	)
end

-- Simulate SAPP unloading the target script.
OnScriptUnload()

-- Report status
local final_msg = string.format("(ran %d tests)", test_count)
if test_failures == 0 then
	print("All tests passed " .. final_msg)
else
	print(string.format("%d TEST FAILURE(S)! %s", test_failures, final_msg))
	os.exit(1)
end
