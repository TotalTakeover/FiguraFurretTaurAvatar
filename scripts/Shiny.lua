-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")

-- Synced variables setup
local shiny = sync.new("ShinyToggle", vec(client.uuidToIntArray(avatar:getUUID())).x % 4096 == 0):config()

-- All shiny parts
local shinyParts = parts:createTable(function(part) return part:getName():find("_[sS]hiny") end)

-- Variables
local wasShiny = not shiny.curr
local initAvatarColor = vectors.hexToRGB(avatar:getColor() or "default")
local initGlowColor = renderer:getOutlineColor() or vec(1, 1, 1)

-- Textures
local normalTex = textures["textures.furret"]       or textures["FurretTaur.furret"]
local shinyTex  = textures["textures.furret_shiny"] or textures["FurretTaur.furret_shiny"]

function events.RENDER(delta, context)
	
	-- Shiny textures
	if shiny.curr ~= wasShiny then
		for _, part in ipairs(shinyParts) do
			part:primaryTexture("CUSTOM", shiny.curr and shinyTex or normalTex)
		end
	end
	
	-- Store data
	wasShiny = shiny.curr
	
	-- Avatar color
	avatar:color(shiny.curr and vectors.hexToRGB("FF8EBC") or initAvatarColor)
	
	-- Glowing outline
	renderer:outlineColor(shiny.curr and vectors.hexToRGB("FF8EBC") or initGlowColor)
	
end

-- Apply sound function
shiny:addFunc(function()
	if player:isLoaded() and shiny.curr then
		sounds:playSound("block.amethyst_block.chime", player:getPos())
	end
end)

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, pageNav, acts, colors = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Pokeball") -- Tries to find script, not required

-- Dont preform if color properties is empty
if next(colors) ~= nil then
	
	-- Store init colors
	local initColors = {}
	for k, v in pairs(colors) do
		initColors[k] = v
	end
	
	-- Create shiny colors
	local shinyColors = {
		hover     = vectors.hexToRGB("DCC4CE"),
		active    = vectors.hexToRGB("D5688E"),
		primary   = "#D5688E",
		secondary = "#DCC4CE"
	}
	
	-- Update action wheel colors
	function events.RENDER(delta, context)
		
		for k in pairs(colors) do
			colors[k] = shiny.curr and shinyColors[k] or initColors[k]
		end
		
	end
	
end

-- Check for if page already exists
local pageExists = action_wheel:getPage("Furret")

-- Pages
local parentPage = action_wheel:getPage("Main")
local furretPage = pageExists or action_wheel:newPage("Furret")

-- Actions
if not pageExists then
	acts.furretPage = parentPage:newAction()
		:item("cobblemon:lucky_egg", "rabbit_hide")
		:onLeftClick(function() pageNav.descend(furretPage) end)
end

acts.shinyToggle = furretPage:newAction()
	:item("gunpowder")
	:toggleItem("glowstone_dust")
	:onToggle(function(bool)
		shiny:update(bool)
	end)
	:toggled(shiny.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if acts.furretPage then
			acts.furretPage
				:title(toJson(
					{text = "Furret Settings", bold = true, color = colors.primary}
				))
				:hoverColor(colors.hover)
		end
		
		acts.shinyToggle
			:title(toJson(
				{
					"",
					{text = "Toggle Shiny Textures\n\n", bold = true, color = colors.primary},
					{text = "Toggles the usage of shiny textures for your pokemon parts.", color = colors.secondary}
				}
			))
			:hoverColor(colors.hover)
			:toggleColor(colors.active)
		
	end
	
end