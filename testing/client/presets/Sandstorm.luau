--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ambience = require(ReplicatedStorage.Package)
local Track = Ambience.Track

local function makeSound(id: string, volume: number, looped: boolean?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped or false
	return sound
end

local windLoop = makeSound("rbxassetid://5799870105", 0.6, true)

return Ambience.preset({
	priority = 15,
	lighting = {
		Lighting = {
			FogEnd = 400,
			FogStart = 20,
			FogColor = Color3.fromRGB(190, 165, 120),
			Brightness = function(current: number)
				return current * 0.6
			end,
			OutdoorAmbient = Color3.fromRGB(160, 140, 100),
		},
		Atmosphere = {
			Density = 0.6,
			Haze = 6,
			Color = Color3.fromRGB(210, 180, 130),
			Offset = 0.4,
		},
		ColorCorrectionEffect = {
			Saturation = -0.4,
			TintColor = Color3.fromRGB(230, 210, 170),
			Contrast = 0.1,
			Enabled = true,
		},
		SunRaysEffect = {
			Intensity = 0,
			Spread = 0,
		},
		Clouds = {
			Cover = 0.9,
			Color = Color3.fromRGB(200, 180, 140),
		},
		Workspace = {
			GlobalWind = Vector3.new(25, 0, 10),
		},
	},
	sounds = {
		Track.looping(windLoop):ModifyVolume(1.2):AutoFadeInOut(2),
	},
})
