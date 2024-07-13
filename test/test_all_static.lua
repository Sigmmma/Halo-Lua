dofile("./shared/static.lua")

-- Commented out scripts we don't have mocked SAPP globals for.
local scripts = {
	--"../anti-cram.lua",
	--"../anti-lagspawn.lua",
	"../anti-speedhack.lua",
	"../commands.lua",
	"../game_clock.lua",
	--"../hit_reg_fix.lua",
	--"../logging.lua",
	--"../map_download.lua",
	--"../motd.lua",
	--"../nameban.lua",
	"../race_checkpoints.lua",
	"../seats.lua",
	"../spawn_point_suppression.lua",
	"../spawn_w_pistol.lua",
	"../spoof_scrimmode.lua",
	"../tk_kick.lua",
	"../votekick.lua",
}

describe("Static check all scripts", function()
	for _, script in pairs(scripts) do
		RunStaticTests(script)
	end
end)
