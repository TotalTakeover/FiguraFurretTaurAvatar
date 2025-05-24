-- Required script
local gaze = require("lib.Gaze")

-- Animations setup
local anims = animations.FurretTaur

-- Gaze setup
local earsGaze = gaze:newGaze()
earsGaze:newAnim(
	anims.horizontalEars,
	anims.verticalEars
)
gaze:unsetPrimary(earsGaze)

-- Gaze config
earsGaze.config.socialInterest = 0
earsGaze.config.soundInterest = 1
earsGaze.config.lookInterval = 10