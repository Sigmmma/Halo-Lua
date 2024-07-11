-- Anti-speedhack by Devieth
-- Refactor and decay added by Mimickal
-- For SAPP

-- SAPP global https://halo-sapp.readthedocs.io/en/latest/scripting/global.html
lua_api_version = "1.10.0.0"
TICKS_PER_SEC = 30

---------------------------------
-- Script configuration values --
---------------------------------

-- Delay for kicking a player once they exceed the active violation threshold.
KICK_TIMER_TICKS = 30 * TICKS_PER_SEC
-- Active violation decay rate. One violation is removed every interval.
VIOLATION_DECAY_TICKS = 2 * TICKS_PER_SEC
-- Active violations needed to trigger a kick timer.
VIOLATION_KICK_THRESHOLD = 5
-- Number of rapid violations needed to kill a player.
VIOLATION_KILL_THRESHOLD = 5
-- The time window for counting rapid violations (violations within this window are considered "rapid").
VIOLATION_KILL_TICKS = 3 * TICKS_PER_SEC

---------------------
-- Event callbacks --
---------------------

local players = {}

-- Global function called by SAPP. Registers event handlers.
-- See https://halo-sapp.readthedocs.io/en/latest/scripting/event.html
function OnScriptLoad()
	register_callback(cb['EVENT_TICK'],  'OnTick')
	register_callback(cb['EVENT_JOIN'],  'OnPlayerJoin')
	register_callback(cb['EVENT_LEAVE'], 'OnPlayerLeave')
end

-- Global function called by SAPP. We don't use it, but it needs to be defined.
function OnScriptUnload() end

function OnPlayerJoin(player_index)
	players[player_index] = Player:new(player_index)
end

function OnPlayerLeave(player_index)
	players[player_index] = nil
end

function OnEventTick()
	-- pairs skips nil values, so this should be safe
	for _, player in pairs(players) do
		player:updateOnTick()
	end
end

------------------------------------------------
-- Player class                               --
-- (This is where the script logic lives too) --
------------------------------------------------
Player = {}

function Player:new(player_index)
	-- Lua class magic. See https://www.lua.org/pil/16.1.html
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	-- This is our stuff
	self.index = player_index
	self.last_tick = nil
	self.timers = {
		decay = Timer:new(),
		kick = Timer:new(),
		kill = Timer:new(),
	}
	self.violations = {
		active = 0,
		rapid = 0,
		total = 0,
	}

	return instance
end

function Player:updateOnTick()
	-- There might be a race condition on the tick a player leaves, depending on
	-- how SAPP orders events. Let's just double-check to be safe.
	if not player_present(self.index) then return end

	self:detectTickViolation()
	self:decayViolations()
	self:punishViolations()

	-- This should happen last
	for _, timer in self.timers do
		timer:tick()
	end
end

function Player:detectTickViolation()
	local cur_tick = self:getTickIndex()

	-- Handle tick index wrap-around case.
	-- Tick index wraps around to 0 after 32 for normal servers, and 63 for lan.
	local good_wrap_around = (
		cur_tick == 0 and (self.last_tick == 32 or self.last_tick == 63)
	)

	if self.last_tick ~= nil and not good_wrap_around then
		-- A tick delta greater than 1 means the server processed multiple
		-- ticks for this player since the last server tick.
		local tick_delta = cur_tick - self.last_tick
		if tick_delta > 1 then
			self.violations.active = self.violations.active + 1
			self.violations.rapid = self.violations.rapid + 1
			self.violations.total = self.violations.total + 1
		end
	end

	self.last_tick = cur_tick
end

function Player:decayViolations()
	if self.violations.active > 0 then
		self.timers.decay:setIfInactive(VIOLATION_DECAY_TICKS)

		if self.timers.decay:expired() then
			self.violations.active = self.violations.active - 1
		end
	else
		self.timers.decay:clear()
	end

	if self.violations.rapid > 0 then
		-- Dividing total time interval by number of violations allows us
		-- to use a single timer to track any number of violations.
		self.timers.kill:setIfInactive(
			math.floor(VIOLATION_KILL_TICKS / VIOLATION_KILL_THRESHOLD)
		)

		if self.timers.kill:expired() then
			self.violations.rapid = self.violations.rapid - 1
			-- timer will reset on next iteration if there are remaining violations
		end
	else
		self.timers.kill:clear()
	end
end

function Player:punishViolations()
	if self.violations.active > VIOLATION_KICK_THRESHOLD then
		-- Player will be kicked if they're still above the treshold when this timer expires.
		self.timers.kick:setIfInactive(KICK_TIMER_TICKS)

		if self.timers.kick:expired() then
			self:kick()
			return
		end
	else
		self.timers.kick:clear()
	end

	-- Kill the player if they've had too many violations in a short window.
	if self.violations.rapid > VIOLATION_KILL_THRESHOLD then
		self:kill()
		self.violations.rapid = 0
		self.timers.kill:clear()
	end

	-- Warn player about active kick timer
	if self.timers.kick:active() then
		self:printKickTimer()
	end
end

-- This value behaves like a counter that increments every tick, then wraps
-- around once it hits a threshold (likely some internal buffer size).
-- For standard servers, that wrap value is 32. In some cases it's 63.
-- This shouldn't be relevant for the current iteration of this script, but I've
-- documented it for future reference.
function Player:getTickIndex()
	return read_word(get_player(self.index) + 0xF4)
end

function Player:kick()
	say_all(string.format(
		"Autokick: %s was kicked due to lag or speed-hack",
		get_var(self.index, "$name")
	))
	execute_command(string.format("sv_kick %d", self.index))
end

-- Kills the player without affecting their score, respawning them instantly.
function Player:kill()
	destroy_object(read_dword(get_player(self.index) + 0x34))
end

function Player:printKickTimer()
	local timer_in_secs = math.floor(self.timers.kick.value / TICKS_PER_SEC)
	rprint(self.index, string.rep(' ', 25))
	-- TODO clean this output up
	rprint(self.index, '|cYou are moving illegally!|ncff0000')
	rprint(self.index, '|tPossible issues:|tPlease fix or kick will occur in: ' .. timer_in_secs)
	rprint(self.index, '|tPacket loss/lag.')
	rprint(self.index, '|tSpeed-hacking.')
end

-----------------
-- Timer class --
-----------------
Timer = {}

function Timer:new()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self
	self.value = nil
	return instance
end

function Timer:active()
	return self.value ~= nil
end

function Timer:clear()
	self.value = nil
end

function Timer:expired()
	return self:active() and self.value <= 0
end

function Timer:set(value)
	self.value = value
end

function Timer:setIfInactive(value)
	if not self:active() or self:expired() then
		self:set(value)
	end
end

function Timer:tick()
	if self:active() and not self:expired() then
		self.value = self.value - 1
	end
end
