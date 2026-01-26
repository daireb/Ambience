--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambience = require(ReplicatedStorage.Package)
local Soundscape = Ambience.Soundscape
local Track = Ambience.SoundscapeTrack

-- Create sound instances
local function makeSound(id: string, volume: number, looped: boolean?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped or false
	return sound
end

-- Rain ambient loop
local rainAmbient = makeSound("rbxassetid://9064263922", 0.5, true)

-- Thunder sounds
local thunderSounds = {
	makeSound("rbxassetid://4961240438", 0.8),
}

local soundscape = Soundscape.new("rain", {
	-- Main rain loop
	Track.looping(rainAmbient)
		:ModifyVolume(0.7)
		:AutoFadeInOut(3),

	-- Occasional thunder with random delays
	Track.random(thunderSounds)
		:ModifyVolume(0.6)
		:AddRandomDelay(10, 30),
})

return soundscape
