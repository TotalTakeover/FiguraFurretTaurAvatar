-- Required script
local parts = require("lib.PartsAPI")

-- Config setup
config:name("FurretTaur")
local shiny = config:load("ColorShiny") or false

-- All shiny parts
local shinyParts = parts:createTable(function(part) return part:getName():find("_[sS]hiny") end)

-- Textures
local normalTex = textures["textures.furret"]       or textures["FurretTaur.furret"]
local shinyTex  = textures["textures.furret_shiny"] or textures["FurretTaur.furret_shiny"]

function events.RENDER(delta, context)
	
	-- Shiny textures
	for _, part in ipairs(shinyParts) do
		part:primaryTexture("CUSTOM", shiny and shinyTex or normalTex)
	end
	
	-- Glowing outline
	renderer:outlineColor(shiny and vectors.hexToRGB("FF8EBC") or vectors.hexToRGB("A77962"))
	
	-- Avatar color
	avatar:color(shiny and vectors.hexToRGB("FF8EBC") or vectors.hexToRGB("A77962"))
	
end

-- Shiny toggle
function pings.setColorShiny(boolean)
	
	shiny = boolean
	config:save("ColorShiny", shiny)
	if player:isLoaded() and shiny then
		sounds:playSound("block.amethyst_block.chime", player:getPos())
	end
	
end

-- Sync variable
function pings.syncColor(a)
	
	shiny = a
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local itemCheck = require("lib.ItemCheck")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncColor(shiny)
	end
	
end

-- Table setup
local c = {}

-- Action variables
c.hover     = vectors.vec3()
c.active    = vectors.vec3()
c.primary   = "#"..vectors.rgbToHex(vectors.vec3())
c.secondary = "#"..vectors.rgbToHex(vectors.vec3())

function events.RENDER(delta, context)
	
	-- Set colors
	c.hover     = shiny and vectors.hexToRGB("DCC4CE") or vectors.hexToRGB("D2AF9D")
	c.active    = shiny and vectors.hexToRGB("D5688E") or vectors.hexToRGB("775043")
	c.primary   = "#"..(shiny and "D5688E" or "775043")
	c.secondary = "#"..(shiny and "DCC4CE" or "D2AF9D")
	
end

-- Table setup
local t = {}

-- Action
t.shinyAct = action_wheel:newAction()
	:item(itemCheck("gunpowder"))
	:toggleItem(itemCheck("glowstone_dust"))
	:onToggle(pings.setColorShiny)

-- Update action
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		t.shinyAct
			:title(toJson
				{"",
				{text = "Toggle Shiny Textures\n\n", bold = true, color = c.primary},
				{text = "Toggles the usage of shiny textures for your pokemon parts.", color = c.secondary}}
			)
			:toggled(shiny)
		
		for _, page in pairs(t) do
			page:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end

-- Return variables/actions
return c, t