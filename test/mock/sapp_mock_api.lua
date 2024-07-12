-- Provides fake versions of SAPP's global functions for local testing.
-- Also provides static type hinting in local development.
-- See here for API we're copying https://halo-sapp.readthedocs.io/en/latest/scripting/game.html
-- This works best with Visual Studio Code (including VSCodium).

-- TODO only implemented what I need so far.

cb = {
	["EVENT_ALIVE"]              = 0,
	["EVENT_AREA_ENTER"]         = 1,
	["EVENT_AREA_EXIT"]          = 2,
	["EVENT_ASSIST"]             = 3,
	["EVENT_BETRAY"]             = 4,
	["EVENT_CAMP"]               = 5,
	["EVENT_CHAT"]               = 6,
	["EVENT_COMMAND"]            = 7,
	["EVENT_CUSTOM"]             = 8,
	["EVENT_DAMAGE_APPLICATION"] = 9,
	["EVENT_DIE"]                = 10,
	["EVENT_ECHO"]               = 11,
	["EVENT_GAME_END"]           = 12,
	["EVENT_GAME_START"]         = 13,
	["EVENT_JOIN"]               = 14,
	["EVENT_KILL"]               = 15,
	["EVENT_LEAVE"]              = 16,
	["EVENT_LOGIN"]              = 17,
	["EVENT_MAP_RESET"]          = 18,
	["EVENT_OBJECT_SPAWN"]       = 19,
	["EVENT_PREJOIN"]            = 20,
	["EVENT_PRESPAWN"]           = 21,
	["EVENT_SCORE"]              = 22,
	["EVENT_SNAP"]               = 23,
	["EVENT_SPAWN"]              = 24,
	["EVENT_STICK"]              = 25,
	["EVENT_SUICIDE"]            = 26,
	["EVENT_TEAM_SWITCH"]        = 27,
	["EVENT_TICK"]               = 28,
	["EVENT_VEHICLE_ENTER"]      = 29,
	["EVENT_VEHICLE_EXIT"]       = 30,
	["EVENT_WARP"]               = 31,
	["EVENT_WEAPON_DROP"]        = 32,
	["EVENT_WEAPON_PICKUP"]      = 33,
}

---@param object_id number
function destroy_object(object_id) end

---@param command string
---@param player_index number?
---@param echo boolean?
function execute_command(command, player_index, echo) end

---@param player_index number
---@return number
function get_player(player_index) end

---@param player_index number
---@param variable string
---@return number|string|boolean
function get_var(player_index, variable) end

---@param player_index number
---@return boolean
function player_present(player_index) end

---@param address number
---@return number
function read_dword(address) end

---@param callback number
---@param function_name string
function register_callback(callback, function_name)
	if callback == nil then
		error("Invalid callback name")
	end

	SAPPMock.callbacks[callback] = function_name
end

---@param player_index number
---@param message string
function rprint(player_index, message) end

---@param message string
function say_all(message) end
