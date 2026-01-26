--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambience = require(ReplicatedStorage.Package)
local LightingScene = Ambience.LightingScene

local scene = LightingScene.new("night")

scene:SetInitialLighting({
	Lighting = {
		Ambient = Color3.fromRGB(30, 35, 50),
		Brightness = 0.5,
		ColorShift_Bottom = Color3.fromRGB(20, 25, 40),
		ColorShift_Top = Color3.fromRGB(30, 40, 60),
		OutdoorAmbient = Color3.fromRGB(50, 60, 80),
		ShadowSoftness = 0.8,
		GeographicLatitude = 45,
		FogEnd = 3000,
		FogStart = 100,
		FogColor = Color3.fromRGB(20, 25, 40),
	},
	Atmosphere = {
		Density = 0.35,
		Offset = 0,
		Color = Color3.fromRGB(50, 60, 90),
		Decay = Color3.fromRGB(30, 40, 70),
		Glare = 0,
		Haze = 2,
	},
	Sky = {
		CelestialBodiesShown = true,
		MoonAngularSize = 15,
		MoonTextureId = "rbxassetid://6444320592",
		SunAngularSize = 21,
		SunTextureId = "rbxassetid://6444320512",
		StarCount = 5000,
		SkyboxBk = "rbxassetid://6444884337",
		SkyboxDn = "rbxassetid://6444884785",
		SkyboxFt = "rbxassetid://6444884337",
		SkyboxLf = "rbxassetid://6444884337",
		SkyboxRt = "rbxassetid://6444884337",
		SkyboxUp = "rbxassetid://6444884337",
	},
	Clouds = {
		Cover = 0.4,
		Density = 0.2,
		Enabled = true,
		Color = Color3.fromRGB(40, 50, 70),
	},
	SunRaysEffect = {
		Intensity = 0,
		Spread = 0,
		Enabled = false,
	},
	ColorCorrectionEffect = {
		Brightness = -0.1,
		Contrast = 0.15,
		Saturation = -0.2,
		TintColor = Color3.fromRGB(200, 210, 255),
		Enabled = true,
	},
	Workspace = {
		GlobalWind = Vector3.new(2, 0, 1),
	},
	Other = {},
})

return scene
