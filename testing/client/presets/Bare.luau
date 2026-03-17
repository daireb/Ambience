--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ambience = require(ReplicatedStorage.Package)

-- Lighting service properties only — no Sky, Atmosphere, Clouds, or effects.
-- Use this to verify that instance-based groups are destroyed when switching
-- away from a preset that defines them.
return Ambience.preset({
	priority = 0,
	lighting = {
		Lighting = {
			Ambient = Color3.fromRGB(100, 100, 100),
			Brightness = 2,
			ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
			ColorShift_Top = Color3.fromRGB(0, 0, 0),
			OutdoorAmbient = Color3.fromRGB(128, 128, 128),
			ShadowSoftness = 0.2,
			GeographicLatitude = 45,
			FogEnd = 100000,
			FogStart = 0,
			FogColor = Color3.fromRGB(192, 192, 192),
		},
		Workspace = {
			GlobalWind = Vector3.zero,
		},
	},
})
