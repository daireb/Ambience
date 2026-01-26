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

-- Forest ambient birds
local birdsAmbient = makeSound("rbxassetid://9116971174", 0.4, true)

local soundscape = Soundscape.new("forest", {
	-- Main ambient bird loop
	Track.looping(birdsAmbient):ModifyVolume(0.6):AutoFadeInOut(2),
})

return soundscape
