-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts = require("lib.PartsAPI")
local lerp  = require("lib.LerpAPI")
local pose  = require("scripts.Posing")

-- Animation setup
local anims = animations.FurretTaur

-- Config setup
config:name("FurretTaur")
local earFlick = config:load("SquapiEarFlick")
local armsMove = config:load("SquapiArmsMove") or false
if earFlick == nil then earFlick = true end

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getOffsetRot()
	
end

-- Lerp tables
local leftArmLerp  = lerp:new(0.5, armsMove and 1 or 0)
local rightArmLerp = lerp:new(0.5, armsMove and 1 or 0)

-- Squishy ears
local ears = squapi.ear:new(
	parts.group.LeftEar,
	parts.group.RightEar,
	0.25,     -- Range Multiplier (0.25)
	false,    -- Horizontal (false)
	2,        -- Bend Strength (2)
	earFlick, -- Do Flick (earFlick)
	400,      -- Flick Chance (400)
	0.1,      -- Stiffness (0.1)
	0.9       -- Bounce (0.9)
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

-- Squishy vanilla arms
local leftArm = squapi.arm:new(
	parts.group.LeftArm,
	1,     -- Strength (1)
	false, -- Right Arm (false)
	true   -- Keep Position (false)
)

local rightArm = squapi.arm:new(
	parts.group.RightArm,
	1,    -- Strength (1)
	true, -- Right Arm (true)
	true  -- Keep Position (false)
)

-- Arm strength variables
local leftArmStrength  = leftArm.strength
local rightArmStrength = rightArm.strength

-- Squishy taur
local taur = squapi.taur:new(
	parts.group.LowerBody
)

-- Squishy crouch
squapi.crouch(anims.crouch)

function events.TICK()
	
	-- Arm variables
	local handedness  = player:isLeftHanded()
	local activeness  = player:getActiveHand()
	local leftActive  = not handedness and "OFF_HAND" or "MAIN_HAND"
	local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
	local leftSwing   = player:getSwingArm() == leftActive
	local rightSwing  = player:getSwingArm() == rightActive
	local leftItem    = player:getHeldItem(not handedness)
	local rightItem   = player:getHeldItem(handedness)
	local using       = player:isUsingItem()
	local usingL      = activeness == leftActive and leftItem:getUseAction() or "NONE"
	local usingR      = activeness == rightActive and rightItem:getUseAction() or "NONE"
	local bow         = using and (usingL == "BOW" or usingR == "BOW")
	local crossL      = leftItem.tag and leftItem.tag["Charged"] == 1
	local crossR      = rightItem.tag and rightItem.tag["Charged"] == 1
	
	-- Arm movement overrides
	local armShouldMove = pose.swim or pose.elytra or pose.crawl or pose.climb
	
	-- Control targets based on variables
	leftArmLerp.target  = (armsMove or armShouldMove or leftSwing  or bow or ((crossL or crossR) or (using and usingL ~= "NONE"))) and 1 or 0
	rightArmLerp.target = (armsMove or armShouldMove or rightSwing or bow or ((crossL or crossR) or (using and usingR ~= "NONE"))) and 1 or 0
	taur.target         = anims.groundIdle:isPlaying() and 0 or taur.target
	
	-- Control ear flick based on variables
	ears.doEarFlick = earFlick
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local idleTimer   = world.getTime(delta)
	local idleRot     = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	local firstPerson = context == "FIRST_PERSON"
	
	-- Adjust arm strengths
	leftArm.strength  = leftArmStrength  * leftArmLerp.currPos
	rightArm.strength = rightArmStrength * rightArmLerp.currPos
	
	-- Adjust arm characteristics after applied by squapi
	parts.group.LeftArm
		:offsetRot(
			parts.group.LeftArm:getOffsetRot()
			+ ((-idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(leftArmLerp.currPos, 0, 1, 1, 0))
		)
		:pos(parts.group.LeftArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	parts.group.RightArm
		:offsetRot(
			parts.group.RightArm:getOffsetRot()
			+ ((idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(rightArmLerp.currPos, 0, 1, 1, 0))
		)
		:pos(parts.group.RightArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	-- Set visible if in first person
	parts.group.LeftArmFP:visible(firstPerson)
	parts.group.RightArmFP:visible(firstPerson)
	
	-- Set upperbody to offset rot and crouching pivot point
	parts.group.UpperBody
		:rot(-parts.group.LowerBody:getRot())
		:offsetPivot(anims.crouch:isPlaying() and -parts.group.UpperBody:getAnimPos() or 0)
	
	-- Offset smooth torso in various parts
	-- Note: acts strangely with `parts.group.body`
	for _, group in ipairs(parts.group.UpperBody:getChildren()) do
		if group ~= parts.group.Body then
			group:rot(-calculateParentRot(group:getParent()))
		end
	end
	
end

-- Ear flick toggle
function pings.setSquapiEarFlick(boolean)
	
	earFlick = boolean
	config:save("SquapiEarFlick", earFlick)
	
end

-- Arm movement toggle
function pings.setSquapiArmsMove(boolean)
	
	armsMove = boolean
	config:save("SquapiArmsMove", armsMove)
	
end

-- Sync variable
function pings.syncSquapi(a, b)
	
	earFlick = a
	armsMove = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local s, c = pcall(require, "scripts.ColorProperties")
if not s then c = {} end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncSquapi(earFlick, armsMove)
	end
	
end

-- Table setup
local t = {}

-- Actions
t.earsAct = action_wheel:newAction()
	:item(itemCheck("bone"))
	:toggleItem(itemCheck("feather"))
	:onToggle(pings.setSquapiEarFlick)
	:toggled(earFlick)

t.armsAct = action_wheel:newAction()
	:item(itemCheck("red_dye"))
	:toggleItem(itemCheck("rabbit_foot"))
	:onToggle(pings.setSquapiArmsMove)
	:toggled(armsMove)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		t.earsAct
			:title(toJson(
				{
					"",
					{text = "Ear Flick Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the ability for the ears to flick.", color = c.secondary}
				}
			))
		
		t.armsAct
			:title(toJson(
				{
					"",
					{text = "Arm Movement Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = c.secondary}
				}
			))
		
		for _, page in pairs(t) do
			page:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end

-- Return action
return t