-- Required script
require("lib.GSAnimBlend")
local pose = require("scripts.Posing")

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
	local vel = player:getVelocity()
	
	-- Animation states
	local groundIdle = vel.xz:length() == 0
	local isPose     = vel.xz:length() ~= 0
	
	-- Animations
	anims.ground_idle:playing(groundIdle)
	anims.pose:playing(isPose)
	
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
	{ anim = anims.ground_idle, ticks = {7,7} }
	{ anim = anims.pose,        ticks = {7,7} },
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	blend.anim:blendTime(table.unpack(blend.ticks)):onBlend("easeOutQuad")
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	--[[
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:offsetRot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	--]]
	
end