--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambience = require(ReplicatedStorage.Package)
local LightingScene = Ambience.LightingScene

local scene = LightingScene.new("sunset")

scene:SetInitialLighting({
	Lighting = {
		Ambient = Color3.fromRGB(100, 70, 50),
		Brightness = 2,
		ColorShift_Bottom = Color3.fromRGB(50, 30, 20),
		ColorShift_Top = Color3.fromRGB(255, 150, 100),
		OutdoorAmbient = Color3.fromRGB(180, 120, 80),
		ShadowSoftness = 0.5,
		GeographicLatitude = 45,
		FogEnd = 5000,
		FogStart = 0,
		FogColor = Color3.fromRGB(255, 180, 120),
	},
	Atmosphere = {
		Density = 0.4,
		Offset = 0.25,
		Color = Color3.fromRGB(255, 180, 130),
		Decay = Color3.fromRGB(255, 130, 80),
		Glare = 0.5,
		Haze = 2.5,
	},
	Sky = {
		CelestialBodiesShown = true,
		MoonAngularSize = 11,
		MoonTextureId = "rbxassetid://6444320592",
		SunAngularSize = 25,
		SunTextureId = "rbxassetid://6444320512",
		StarCount = 1000,
		SkyboxBk = "rbxassetid://6444884337",
		SkyboxDn = "rbxassetid://6444884785",
		SkyboxFt = "rbxassetid://6444884337",
		SkyboxLf = "rbxassetid://6444884337",
		SkyboxRt = "rbxassetid://6444884337",
		SkyboxUp = "rbxassetid://6444884337",
	},
	Clouds = {
		Cover = 0.6,
		Density = 0.4,
		Enabled = true,
		Color = Color3.fromRGB(255, 200, 150),
	},
	SunRaysEffect = {
		Intensity = 0.25,
		Spread = 1,
		Enabled = true,
	},
	ColorCorrectionEffect = {
		Brightness = 0.05,
		Contrast = 0.2,
		Saturation = 0.3,
		TintColor = Color3.fromRGB(255, 230, 200),
		Enabled = true,
	},
	Workspace = {
		GlobalWind = Vector3.new(3, 0, 1),
	},
	Other = {},
})

return scene
