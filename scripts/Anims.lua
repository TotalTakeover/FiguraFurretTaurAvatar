-- Required script
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local ground  = require("lib.GroundCheck")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.FurretTaur

--[[
-- Parrot pivots
local parrots = {
	
	parts.group.LeftParrotPivot,
	parts.group.RightParrotPivot
	
}
--]]

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getTrueRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

function events.TICK()
	
	-- Variable
	local vel       = player:getVelocity()
	local sprinting = player:isSprinting()
	local onGround  = ground()
	
	-- Animation variables
	isSprinting = sprinting and not pose.crouch and not pose.swim
	
	-- Speed control
	local walkSpeed   = math.min(vel.xz:length() * 5, 3)
	local sprintSpeed = math.min(vel.xz:length() * 3.7, 1.5)
	
	-- Animation speeds
	anims.walk:speed(walkSpeed)
	anims.walkBounce:speed(walkSpeed)
	anims.sprint:speed(sprintSpeed)
	
	-- Animation states
	local groundIdle = vel.xz:length() == 0
	local walk       = vel.xz:length() ~= 0 and (onGround or pose.swim or effects.cF) and not isSprinting
	local walkBounce = walk and not pose.swim
	local sprint     = vel.xz:length() ~= 0 and (onGround or effects.cF) and isSprinting
	local jump       = vel.xz:length() ~= 0 and not onGround
	
	-- Animations
	anims.groundIdle:playing(groundIdle)
	anims.walk:playing(walk)
	anims.walkBounce:playing(walkBounce)
	anims.sprint:playing(sprint)
	anims.jump:playing(jump)
	
end

function events.RENDER(delta, context)
	
	--[[
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - vanilla_model.BODY:getOriginRot())
	end
	--]]
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.groundIdle, ticks = {7,7} },
	{ anim = anims.walk,       ticks = {7,7} },
	{ anim = anims.sprint,     ticks = {3,7} },
	{ anim = anims.jump,       ticks = {7,7} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	blend.anim:blendTime(table.unpack(blend.ticks)):onBlend("easeOutQuad")
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:offsetRot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end