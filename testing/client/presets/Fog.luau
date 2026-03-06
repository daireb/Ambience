--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ambience = require(ReplicatedStorage.Package)

return Ambience.preset({
	priority = 5,
	lighting = {
		Lighting = {
			FogEnd = function(current: number)
				return current * 0.3
			end,
			FogStart = 0,
			FogColor = function(current: Color3)
				return current:Lerp(Color3.fromRGB(180, 185, 190), 0.6)
			end,
			Brightness = function(current: number)
				return current * 0.8
			end,
		},
		Atmosphere = {
			Density = function(current: number)
				return current + 0.25
			end,
			Haze = function(current: number)
				return current + 3
			end,
			Color = function(current: Color3)
				return current:Lerp(Color3.fromRGB(200, 205, 210), 0.5)
			end,
		},
		SunRaysEffect = {
			Intensity = 0,
			Spread = 0,
		},
		Clouds = {
			Cover = function(current: number)
				return math.min(current + 0.3, 1)
			end,
		},
	},
})
