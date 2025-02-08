-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.FurretTaur

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
	local vel       = player:getVelocity()
	local dir       = player:getLookDir()
	local sprinting = player:isSprinting()
	local onGround  = ground()
	
	-- Directional velocity
	local fbVel = player:getVelocity():dot((dir.x_z):normalize())
	local lrVel = player:getVelocity():cross(dir.x_z:normalize()).y
	
	-- Animation variables
	isSprinting = sprinting and not pose.crouch and not pose.swim
	
	-- Speed control
	local walkSpeed   = math.clamp(fbVel < -0.05 and math.min(fbVel, math.abs(lrVel)) * 5 or math.max(fbVel, math.abs(lrVel)) * 5, -3, 3)
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
	
end

function events.RENDER(delta, context)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - vanilla_model.BODY:getOriginRot())
	end
	
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
	blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:offsetRot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end