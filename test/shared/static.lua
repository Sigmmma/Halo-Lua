local B = require("busted")
dofile("./shared/util.lua")

---Loads and checks the given SAPP Lua script for common errors.
---@param lua_file string Path to a lua script file
function RunStaticTests(lua_file)
	B.describe(lua_file .. " static tests", function()
		-- Load SAPP mocks so the target script can call them
		dofile("./mock/sapp_mock_api.lua")
		dofile("./mock/sapp_mock_game_state.lua")

		-- NOTE: synax errors are caught with a runtime error here.
		dofile(lua_file)
		B.it("Syntax check", function() end)

		B.it("Defines global function 'OnScriptLoad'", function()
			B.assert.are.equal(type(OnScriptLoad), "function")
		end)

		B.it("Defines global function 'OnScriptUnload", function()
			B.assert.are.equal(type(OnScriptUnload), "function")
		end)

		-- Simulate SAPP loading the target script.
		-- NOTE: invalid callback table names are caught with a runtime error here.
		OnScriptLoad()
		if TableSize(SAPPMock.callbacks) > 0 then
			B.it("Callback table names are valid")
		end

		B.it("Defines global value 'api_version'", function()
			B.assert.truthy(api_version)
		end)

		for cb_index, func_name in pairs(SAPPMock.callbacks) do
			local cb_name = GetKeyForValue(cb, cb_index)
			B.it(string.format("Callback %s function exists", cb_name), function()
				B.assert.are.equal(type(_G[func_name]), "function")
			end)
		end

		-- Simulate SAPP unloading the target script.
		OnScriptUnload()
	end)
end
