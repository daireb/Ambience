--!strict
--[[
	Ambience - Unified ambient lighting and sound system for Roblox

	Usage:
	```lua
	local Ambience = require(path.to.Ambience)

	-- Lighting
	Ambience.Lighting.Register(myScene)
	Ambience.Lighting.SetActive("sunset", { tweenTime = 2 })

	-- Sound
	Ambience.Sound.Register(mySoundscape)
	Ambience.Sound.SetActive("forest", { fadeTime = 1 })
	```
]]

local Lighting = require(script.LightingSceneService)
local Sound = require(script.Soundscapes)

export type LightingScene = Lighting.LightingScene
export type LightingData = Lighting.LightingData
export type Soundscape = Sound.Soundscape
export type SoundscapeTrack = Sound.SoundscapeTrack

return {
	Lighting = Lighting,
	Sound = Sound,

	-- Re-export constructors for convenience
	LightingScene = Lighting.Scene,
	Soundscape = Sound.Soundscape,
	SoundscapeTrack = Sound.Track,
}
