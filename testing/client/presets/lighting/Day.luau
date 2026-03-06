--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambience = require(ReplicatedStorage.Package)
local LightingScene = Ambience.LightingScene

local scene = LightingScene.new("day")

scene:SetInitialLighting({
	Lighting = {
		Ambient = Color3.fromRGB(150, 150, 150),
		Brightness = 3,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(150, 150, 150),
		ShadowSoftness = 0.2,
		GeographicLatitude = 45,
		FogEnd = 100000,
		FogStart = 0,
		FogColor = Color3.fromRGB(192, 216, 255),
	},
	Atmosphere = {
		Density = 0.3,
		Offset = 0,
		Color = Color3.fromRGB(199, 216, 255),
		Decay = Color3.fromRGB(92, 120, 156),
		Glare = 0,
		Haze = 1,
	},
	Sky = {
		CelestialBodiesShown = true,
		MoonAngularSize = 11,
		MoonTextureId = "rbxassetid://6444320592",
		SunAngularSize = 21,
		SunTextureId = "rbxassetid://6444320512",
		StarCount = 3000,
		SkyboxBk = "rbxassetid://6444884337",
		SkyboxDn = "rbxassetid://6444884785",
		SkyboxFt = "rbxassetid://6444884337",
		SkyboxLf = "rbxassetid://6444884337",
		SkyboxRt = "rbxassetid://6444884337",
		SkyboxUp = "rbxassetid://6444884337",
	},
	Clouds = {
		Cover = 0.5,
		Density = 0.3,
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
	},
	SunRaysEffect = {
		Intensity = 0.1,
		Spread = 0.8,
		Enabled = true,
	},
	ColorCorrectionEffect = {
		Brightness = 0,
		Contrast = 0.1,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 255, 255),
		Enabled = true,
	},
	Workspace = {
		GlobalWind = Vector3.new(5, 0, 2),
	},
})

return scene
