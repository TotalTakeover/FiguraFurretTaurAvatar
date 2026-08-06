-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")

-- Animation setup
local anims = animations.FurretTaur

-- Synced variables setup
local earFlick = sync.new("AnimsEarFlicks", true):config()

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getOffsetRot()
	
end

-- Squishy ears
local ears = squapi.ear:new(
	parts.group.LeftEar,
	parts.group.RightEar,
	0,             -- Range Multiplier (0)
	false,         -- Horizontal (false)
	2,             -- Bend Strength (2)
	earFlick.curr, -- Do Flick (earFlick)
	400,           -- Flick Chance (400)
	0.1,           -- Stiffness (0.1)
	0.9            -- Bounce (0.9)
)

-- Tails table
local tailParts = parts:createChain("Tail")

-- Squishy tail
local tail = squapi.tail:new(
	tailParts,
	20,   -- Intensity X (20)
	2.5,  -- Intensity Y (2.5)
	0.8,  -- Speed X (0.8)
	1,    -- Speed Y (1)
	2,    -- Bend (2)
	-1,   -- Velocity Push (-1)
	0,    -- Initial Offset (0)
	1,    -- Seg Offset (1)
	0.01, -- Stiffness (0.01)
	0.9,  -- Bounce (0.9)
	0,    -- Fly Offset (0)
	-20,  -- Down Limit (-20)
	20    -- Up Limit (20)
)

-- Head table
local headParts = {
	
	parts.group.UpperTorso,
	parts.group.UpperBody
	
}

-- Squishy smooth torso
local head = squapi.smoothHead:new(
	headParts,
	0.3,  -- Strength (0.3)
	0.4,  -- Tilt (0.4)
	1,    -- Speed (1)
	false -- Keep Original Head Pos (false)
)

-- Squishy taur
local taur = squapi.taur:new(
	parts.group.LowerBody
)

function events.TICK()
	
	-- Control ear flick based on variables
	ears.doEarFlick = earFlick.curr
	
end

function events.RENDER(delta, context)
	
	-- Set upperbody to offset rot and crouching pivot point
	parts.group.UpperBody:rot(-parts.group.LowerBody:getRot())
	
	-- Offset smooth torso in various parts
	-- Note: acts strangely with `parts.group.body`
	for _, group in ipairs(parts.group.UpperBody:getChildren()) do
		if group ~= parts.group.Body then
			group:rot(-calculateParentRot(group:getParent()))
		end
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, pageNav, acts, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Anims") -- Tries to find script, not required

-- Check for if page already exists
local pageExists = action_wheel:getPage("Anims")

-- Pages
local parentPage = action_wheel:getPage("Main")
local animsPage  = pageExists or action_wheel:newPage("Anims")

-- Actions
if not pageExists then
	acts.animsPage = parentPage:newAction()
		:item("jukebox")
		:onLeftClick(function() pageNav.descend(animsPage) end)
end

acts.animsEarToggle = animsPage:newAction()
	:item("bone")
	:toggleItem("feather")
	:onToggle(function(bool)
		earFlick:update(bool)
	end)
	:toggled(earFlick.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if acts.animsPage then
			acts.animsPage
				:title(toJson(
					{text = "Animation Settings", bold = true, color = c.primary}
				))
				:hoverColor(c.hover)
		end
		
		acts.animsEarToggle
			:title(toJson(
				{
					"",
					{text = "Ear Flick Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the ability for the ears to flick.", color = c.secondary}
				}
			))
			:hoverColor(c.hover)
			:toggleColor(c.active)
		
	end
	
end