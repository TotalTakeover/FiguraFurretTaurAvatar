-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.FurretTaur

-- Synced variables setup
local armsMove = sync.new("AnimsArms", false):config()

-- Arms setup
local leftArmLerp  = lerp.new(armsMove.curr and 1 or 0, 0.5)
local rightArmLerp = lerp.new(armsMove.curr and 1 or 0, 0.5)

-- Gets the origin rotation of a part, clamped
local function getOriginRot(part, delta)
	return (vanilla_model[part]:getOriginRot(delta) + 180) % 360 - 180
end

-- Parrot pivots
local parrots = {
	
	parts.group.LeftParrotPivot,
	parts.group.RightParrotPivot
	
}

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getTrueRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

function events.TICK()
	
	-- Variables
	local vel = player:getVelocity()
	local yaw = player:getBodyYaw()
	local dir = vec(math.sin(math.rad(-yaw)), 0, math.cos(math.rad(-yaw)))
	local sprinting = player:isSprinting()
	local onGround  = ground()
	
	-- Directional velocity
	local fbVel = vel:dot((dir.x_z):normalized())
	local lrVel = vel:crossed(dir.x_z:normalized()).y
	local udVel = vel.y
	
	-- Animation variables
	isSprinting = sprinting and not pose.crouch and not pose.swim
	
	-- Speed control
	local walkSpeed   = math.clamp(fbVel * 5, -3, 3)
	local sprintSpeed = math.min(vel.xz:length() * 3.7, 1.5)
	
	-- Animation speeds
	anims.walk:speed(walkSpeed)
	anims.walkBounce:speed(walkSpeed)
	anims.sprint:speed(sprintSpeed)
	
	-- Animation states
	local groundIdle = vel.xz:length() == 0 and not (player:getVehicle() or pose.sleep or pose.crawl)
	local walk       = (vel.xz:length() ~= 0 or pose.crawl) and (onGround or player:isInWater() or effects.cF) and not (isSprinting or player:getVehicle() or pose.sleep)
	local walkBounce = walk and onGround and not pose.swim
	local sprint     = vel.xz:length() ~= 0 and (onGround or effects.cF) and isSprinting and not (player:getVehicle() or pose.sleep)
	local jump       = vel.xz:length() ~= 0 and not (onGround or player:getVehicle() or pose.sleep)
	local ride       = player:getVehicle()
	local sleep      = pose.sleep
	local crawl      = pose.crawl or pose.swim
	
	-- Animations
	anims.groundIdle:playing(groundIdle)
	anims.walk:playing(walk)
	anims.walkBounce:playing(walkBounce)
	anims.sprint:playing(sprint)
	anims.jump:playing(jump)
	anims.ride:playing(ride)
	anims.sleep:playing(sleep)
	anims.crawl:playing(crawl)
	
	-- Arm variables
	local handedness = player:isLeftHanded()
	local mainL = not handedness and "OFF_HAND" or "MAIN_HAND"
	local mainR = handedness and "OFF_HAND" or "MAIN_HAND"
	local swingL = player:getSwingArm() == mainL
	local swingR = player:getSwingArm() == mainR
	local using = player:isUsingItem()
	local active = player:getActiveHand()
	local itemL = player:getHeldItem(not handedness)
	local itemR = player:getHeldItem(handedness)
	local usingL = using and active == mainL and itemL:getUseAction()
	local usingR = using and active == mainR and itemR:getUseAction()
	local bow = (usingL or usingR or ""):find("BOW") or (itemL:getTag().Charged or itemR:getTag().Charged) == 1
	
	-- Arms movement override
	local armShouldMove = pose.swim or pose.elytra or pose.crawl or pose.climb
	
	-- Arms movement targets
	leftArmLerp.target  = (armsMove.curr or armShouldMove or swingL or usingL or bow) and 0 or -1
	rightArmLerp.target = (armsMove.curr or armShouldMove or swingR or usingR or bow) and 0 or -1
	
end

function events.RENDER(delta, context)
	
	-- Arm idle rotation
	local idleTimer = world.getTime(delta)
	local idleRot   = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	
	-- Apply arm rotations
	parts.group.LeftArm:offsetRot((getOriginRot("LEFT_ARM", delta) + idleRot) * leftArmLerp.currPos)
	parts.group.RightArm:offsetRot((getOriginRot("RIGHT_ARM", delta) - idleRot) * rightArmLerp.currPos)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - getOriginRot("BODY", delta))
	end
	
	-- Crouch offset
	local bodyRot = getOriginRot("BODY", delta)
	local crouchPos = vec(0, -math.sin(math.rad(bodyRot.x)) * 2, -math.sin(math.rad(bodyRot.x)) * 12)
	parts.group.UpperBody:offsetPivot(crouchPos):pos(-crouchPos.x_z + crouchPos._y_)
	parts.group.LowerBody:pos(crouchPos)
	
	-- Spyglass rotations
	local headRot = getOriginRot("HEAD", delta)
	headRot.x = math.clamp(headRot.x, -90, 30)
	parts.group.Spyglass:offsetRot(headRot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.groundIdle, ticks = {7,7} },
	{ anim = anims.walk,       ticks = {7,7} },
	{ anim = anims.sprint,     ticks = {3,7} },
	{ anim = anims.jump,       ticks = {7,7} },
	{ anim = anims.ride,       ticks = {7,7} },
	{ anim = anims.sleep,      ticks = {7,7} },
	{ anim = anims.crawl,      ticks = {7,7} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	if blend.anim ~= nil then
		blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
	end
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local s, pageNav, acts, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

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

acts.animsArmsToggle = animsPage:newAction()
	:item("red_dye")
	:toggleItem("rabbit_foot")
	:onToggle(function(bool)
		armsMove:update(bool)
	end)
	:toggled(armsMove.curr)

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
		
		acts.animsArmsToggle
			:title(toJson(
				{
					"",
					{text = "Arm Movement Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = c.secondary}
				}
			))
			:hoverColor(c.hover)
			:toggleColor(c.active)
		
	end
	
end