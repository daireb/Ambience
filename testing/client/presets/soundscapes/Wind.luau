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

-- Wind ambient loop
local windAmbient = makeSound("rbxassetid://5799870105", 0.4, true)

local soundscape = Soundscape.new("wind", {
	-- Main wind loop with subtle volume variation
	Track.looping(windAmbient)
		:ModifyVolume(function(sound: Sound)
			-- Subtle breathing effect using sine wave
			local time = tick()
			return 0.7 + 0.3 * math.sin(time * 0.5)
		end)
		:AutoFadeInOut(2),
})

return soundscape
