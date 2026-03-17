--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ambience = require(ReplicatedStorage.Package)

-- Partially-defined instance groups. Properties omitted here should resolve
-- to Roblox Studio defaults, NOT retain stale values from a previous preset.
--
-- Test: "Set Day" then "Set Partial" and verify:
--   - ColorCorrectionEffect.Saturation reverts to 0 (not Day's 0.1)
--   - Atmosphere.Haze reverts to 0 (not Day's 1)
--   - Clouds.Cover reverts to 0.5 (not Day's 0.5 -- same in this case)
--   - Sky is still present with default star count etc.
return Ambience.preset({
	priority = 0,
	lighting = {
		Lighting = {
			Brightness = 2,
			Ambient = Color3.fromRGB(80, 80, 80),
		},
		ColorCorrectionEffect = {
			Brightness = 0.2,
			Enabled = true,
		},
		Atmosphere = {
			Density = 0.5,
		},
		Sky = {
			CelestialBodiesShown = true,
		},
	},
})
