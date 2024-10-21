-- Required script
local parts = require("lib.PartsAPI")

-- Play sound
function pings.playPokemonCry()
	
	if player:isLoaded() then
		sounds:playSound("cobblemon:pokemon.furret.cry", player:getPos(), 0.6, math.random()*0.35+0.85)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Config setup
config:name("FurretTaur")

-- Variable
local cooldown = 0

-- Cry Keybind
local cryBind   = config:load("CryKeybind") or "key.keyboard.keypad.2"
local setCryKey = keybinds:newKeybind("Pokemon Cry"):onPress(function() pings.playPokemonCry() cooldown = 30 end):key(cryBind)

function events.TICK()
	
	-- Reduce cooldown
	cooldown = math.max(cooldown - 1, 0)
	
	-- Disable keybind if cooldown is active, and player isnt dead
	setCryKey:enabled(cooldown == 0 and player:getDeathTime() == 0)
	
end

-- Keybind updater
function events.TICK()
	
	local cryKey = setCryKey:getKey()
	if cryKey ~= cryBind then
		cryBind = cryKey
		config:save("CryKeybind", cryKey)
	end
	
end