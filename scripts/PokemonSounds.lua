-- Play sound
function pings.playPokemonCry()
	
	if player:isLoaded() then
		sounds:playSound("cobblemon:pokemon.furret.cry", player:getPos(), 0.6, math.random()*0.35+0.85)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local sync = require("lib.LetThatSyncFig")

-- Variable
local cooldown = 0

-- Keybinds
local cryKeybind = keybinds:newKeybind("Pokemon Cry", "key.keyboard.keypad.2")
	:onPress(function() pings.playPokemonCry() cooldown = 30 end)

-- Sync config keybinds
sync.keybind(cryKeybind, "CryKeybind")

function events.TICK()
	
	-- Reduce cooldown
	cooldown = math.max(cooldown - 1, 0)
	
	-- Disable keybind if cooldown is active, and player isnt dead
	cryKeybind:enabled(cooldown == 0 and player:getDeathTime() == 0)
	
end