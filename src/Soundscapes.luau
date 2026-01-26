--!strict
local SoundService = game:GetService("SoundService")

--[[
	daireb's Soundscapes Module


]]

--- A single audio track, a component of a soundscape
type SoundscapeTrack = {
	--- Checks if the track is currently active (i.e. is it playing)
	IsActive: (self: SoundscapeTrack) -> boolean,

	--- Activates the track, starting playback
	Activate: (self: SoundscapeTrack) -> nil,
	--- Stops the track, stopping playback
	Stop: (self: SoundscapeTrack) -> nil,

	--- Modifies the volume of the track during playback. The modifier can be a number (constant volume multiplier) or a function that takes the current Sound and returns a volume multiplier. The function is called every frame while the sound is playing.
	ModifyVolume: (self: SoundscapeTrack, modifier: ((Sound) -> number) | number) -> SoundscapeTrack,
	--- Sets up a volume controller that fades in at the start and fades out at the end of each sound. The optional fade_length parameter specifies how long (in seconds) the fade should take; defaults to 1 second.
	AutoFadeInOut: (self: SoundscapeTrack, fade_length: number?) -> SoundscapeTrack,

	--- Sets up a condition that must be true for the track to start playing. The condition is only checked when the track is about to start a new sound.
	OnlyStartPlayingIf: (self: SoundscapeTrack, callback: () -> boolean) -> SoundscapeTrack,
	--- Sets up a condition that must be true for the track to continue playing. The condition is checked every frame while the sound is playing.
	OnlyPlayWhile: (self: SoundscapeTrack, callback: (Sound) -> boolean) -> SoundscapeTrack,
	--- Adds a random delay before the track loops, between min and max seconds
	AddRandomDelay: (self: SoundscapeTrack, min: number, max: number) -> SoundscapeTrack,

	--- Returns a unique identifier for this track, in the format "SoundscapeName#TrackIndex"
	GetFullId: (self: SoundscapeTrack) -> string,

	_parent: Soundscape?,
	_currentSound: Sound?,
	_pickNextSound: ({ [string]: any }) -> Sound?,
	_computeVolume: (Sound) -> number,
	_continuePlaying: (Sound) -> boolean,
	_data: { [string]: any },
	_playingId: number,
	_transitionVolume: number,
}

--- A collection of tracks that can be activated and deactivated together
export type Soundscape = {
	Id: string,

	Activate: (self: Soundscape) -> nil,
	Stop: (self: Soundscape) -> nil,

	_parent: Soundscape?,
	_tracks: { SoundscapeTrack },
	_isActive: boolean,

	_FadeOutAndStop: (self: Soundscape, duration: number) -> nil,
	_SetTransitionVolume: (self: Soundscape, volume: number) -> nil,
	_FadeIn: (self: Soundscape, duration: number) -> nil,
}

local SOUND_FOLDER = Instance.new("Folder")
SOUND_FOLDER.Name = "SoundscapeSounds"
SOUND_FOLDER.Parent = SoundService

local SoundscapeTrack = {}
SoundscapeTrack.__index = SoundscapeTrack

-- Constructor

--[=[
	Creates a new soundscape track.

	The pick_new_sound function is called whenever the track needs to start playing a new sound. It is passed a table that can be used to store state between calls, and should return the Sound to play, or nil if no sound should be played at this time.

	For example, to create a track that plays a single sound repeatedly:
	```SoundscapeTrack.new(function() return mySound end)```

	Or to create a track that plays a random sound from a list:
	```SoundscapeTrack.new(function() return sounds[math.random(1, #sounds)] end)```
]=]
SoundscapeTrack.new = function(pick_new_sound: ({ [string]: any }) -> Sound?): SoundscapeTrack
	local self = setmetatable({}, SoundscapeTrack)

	self._currentSound = nil
	self._pickNextSound = pick_new_sound

	self._data = {}
	self._computeVolume = function()
		return 1
	end
	self._continuePlaying = function()
		return true
	end

	self._playingId = -1
	self._transitionVolume = 1

	return self :: never
end

-- Helper constructors

--- Creates a new soundscape track that plays a single sound repeatedly
SoundscapeTrack.looping = function(sound: Sound)
	return SoundscapeTrack.new(function()
		return sound
	end)
end

--- Creates a new soundscape track that plays a random sound from the given list each time
SoundscapeTrack.random = function(sounds: { Sound })
	return SoundscapeTrack.new(function()
		return sounds[math.random(1, #sounds)]
	end)
end

-- Changing volume during playback

--- Sets an arbitrary function to compute the volume of the sound during playback
function SoundscapeTrack.ModifyVolume(self: SoundscapeTrack, modifier: ((Sound) -> number) | number)
	local callback: (Sound) -> number = if typeof(modifier) == "number"
		then function()
			return modifier
		end
		else modifier

	local old_callback = self._computeVolume
	self._computeVolume = function(sound: Sound)
		return old_callback(sound) * callback(sound)
	end

	return self
end

function SoundscapeTrack.OnlyPlayWhile(self: SoundscapeTrack, callback: (Sound) -> boolean)
	local old_callback = self._continuePlaying
	self._continuePlaying = function(sound: Sound)
		return old_callback(sound) and callback(sound)
	end

	return self
end

function SoundscapeTrack:AutoFadeInOut(fade_length: number?)
	local len = fade_length or 1

	return self:ModifyVolume(function(sound: Sound)
		local distance = (sound.TimeLength - sound.TimePosition) / len
		return math.clamp(distance, 0, 1) * math.clamp(sound.TimePosition / len, 0, 1)
	end)
end

-- Setting conditions

function SoundscapeTrack.OnlyStartPlayingIf(self: SoundscapeTrack, callback: () -> boolean)
	local old_f = self._pickNextSound

	self._pickNextSound = function(data)
		if not callback() then
			return nil
		end
		return old_f(data)
	end

	return self
end

function SoundscapeTrack.AddRandomDelay(self: SoundscapeTrack, min: number, max: number)
	local old_f = self._pickNextSound

	self._pickNextSound = function(data: { nextSound: number? })
		if data.nextSound == nil then -- first time
			data.nextSound = tick() + min + math.random() * max
		end

		if tick() < data.nextSound :: number then -- still waiting
			return nil
		else -- time to pick a new sound
			data.nextSound = nil
			local new_sound = old_f(data)

			if new_sound then
				data.nextSound = tick() + min + math.random() * max + new_sound.TimeLength
			end

			return new_sound
		end
	end

	return self
end

-- Utility functions

function SoundscapeTrack.GetFullId(self: SoundscapeTrack)
	if self._parent == nil then
		return "unknown#unknown"
	else
		local my_index = table.find(self._parent._tracks, self)
		local index_text = if my_index then tostring(my_index) else "unknown"
		return string.format("%s#%s", self._parent.Id, index_text)
	end
end

-- Activating and stopping the track

function SoundscapeTrack.IsActive(self: SoundscapeTrack)
	return self._playingId ~= -1
end

function SoundscapeTrack.Activate(self: SoundscapeTrack)
	if self._playingId ~= -1 then
		error("SoundscapeTrack is already playing")
	end

	local my_id = tick()
	self._playingId = my_id

	task.spawn(function()
		while self._playingId == my_id do
			if self._currentSound then
				self._currentSound:Stop()
			end

			local base_sound = self._pickNextSound(self._data) :: Sound?

			if not base_sound then
				self._currentSound = nil
				task.wait()
				continue
			end

			local sound = base_sound:Clone()
			sound.Parent = SOUND_FOLDER

			self._currentSound = sound

			sound:Play()
			local base_volume = sound.Volume

			local playing = true

			task.spawn(function()
				while playing and self._currentSound do
					sound.Volume = base_volume * self._computeVolume(self._currentSound) * self._transitionVolume -- Updating volume over time

					local should_be_playing = self._continuePlaying(self._currentSound) -- Updating whether we should be playing
					if not should_be_playing then
						if sound.IsPlaying then
							sound:Pause()
						end
					else
						if not sound.IsPlaying then
							sound:Resume()
						end
					end

					task.wait()
				end
			end)

			sound.Ended:Wait()
			sound:Destroy()
			playing = false
		end
	end)
end

function SoundscapeTrack.Stop(self: SoundscapeTrack)
	if self._playingId == -1 then
		error("SoundscapeTrack is not playing")
	end

	self._playingId = -1

	if self._currentSound then
		self._currentSound:Stop()
		self._currentSound = nil
	end
end

local Soundscape = {}
Soundscape.__index = Soundscape

Soundscape.new = function(id: string, tracks: { SoundscapeTrack }?)
	local self = setmetatable({}, Soundscape)

	self.Id = id
	self._tracks = tracks or {}
	self._isActive = false

	if tracks then
		for i, k in ipairs(tracks) do
			k._parent = self :: never
		end
	end

	return self
end

--- Activates the soundscape, causing all tracks to activate
function Soundscape.Activate(self: Soundscape)
	self._isActive = true

	for _, track in ipairs(self._tracks) do
		if not track:IsActive() then
			track:Activate()
		end
	end
end

--- Stops the soundscape, instantly stopping all tracks
function Soundscape:Stop()
	self._isActive = false

	for _, track in ipairs(self._tracks) do
		if track:IsActive() then
			track:Stop()
		end
	end
end

--- Fades out all tracks over the specified duration, then stops the soundscape
function Soundscape:_FadeOutAndStop(duration: number)
	self._isActive = false
	local start_time = tick()

	task.spawn(function()
		while tick() - start_time < duration do
			local alpha = (tick() - start_time) / duration
			local volume = 1 - alpha

			for _, track in ipairs(self._tracks) do
				track._transitionVolume = volume
			end

			task.wait()
		end

		-- Ensure we're fully faded out and stopped
		for _, track in ipairs(self._tracks) do
			track._transitionVolume = 0
			if track:IsActive() then
				track:Stop()
			end
		end
	end)
end

--- Sets the transition volume for all tracks (used for fade-in)
function Soundscape:_SetTransitionVolume(volume: number)
	for _, track in ipairs(self._tracks) do
		track._transitionVolume = volume
	end
end

--- Fades in all tracks from current transition volume to 1 over the specified duration
function Soundscape:_FadeIn(duration: number)
	local start_time = tick()

	task.spawn(function()
		while tick() - start_time < duration do
			local alpha = (tick() - start_time) / duration

			for _, track in ipairs(self._tracks) do
				track._transitionVolume = alpha
			end

			task.wait()
		end

		-- Ensure we're fully faded in
		for _, track in ipairs(self._tracks) do
			track._transitionVolume = 1
		end
	end)
end

--- Options for SetActive
type SetActiveOptions = {
	fadeTime: number?,
}

local SoundscapeHandler = {}

SoundscapeHandler.Track = SoundscapeTrack
SoundscapeHandler.Soundscape = Soundscape

local soundscapes: { [string]: Soundscape } = {}
local current_soundscape: Soundscape? = nil

--- Registers a soundscape so it can be activated later
SoundscapeHandler.Register = function(soundscape: Soundscape)
	if soundscapes[soundscape.Id] then
		error(`A soundscape with Id "{soundscape.Id}" has already been registered!`)
	end

	soundscapes[soundscape.Id] = soundscape
end

--- Finds all ModuleScripts in a Folder and registers the soundscapes they return
SoundscapeHandler.RegisterFromFolder = function(folder: Folder)
	for _, k in ipairs(folder:GetDescendants()) do
		if k:IsA("ModuleScript") then
			local soundscape = require(k) :: Soundscape
			SoundscapeHandler.Register(soundscape)
		end
	end
end

--- Gets a registered soundscape by its Id. Returns nil if no soundscape with the given Id is registered.
SoundscapeHandler.Get = function(id: string): Soundscape?
	return soundscapes[id]
end

--- Returns a dictionary of all registered soundscapes
SoundscapeHandler.GetAll = function()
	return soundscapes
end

--- Returns the currently active soundscape, or nil if none is active
SoundscapeHandler.GetActive = function(): Soundscape?
	return current_soundscape
end

--- Sets the current soundscape, stopping the previous one if necessary. If options.fadeTime is provided, crossfades between soundscapes.
SoundscapeHandler.SetActive = function(id: string?, options: SetActiveOptions?)
	local new_soundscape = if id then soundscapes[id] else nil
	if id and not new_soundscape then
		error(`No soundscape with Id "{id}" has been registered!`)
	end

	-- Check if we're already in this soundscape
	if current_soundscape == new_soundscape then
		return
	end

	local fade_time = options and options.fadeTime

	-- Handle the old soundscape
	if current_soundscape then
		if fade_time and fade_time > 0 then
			current_soundscape:_FadeOutAndStop(fade_time)
		else
			current_soundscape:Stop()
		end
	end

	-- Update to the new soundscape and activate it if needed
	current_soundscape = new_soundscape
	if current_soundscape then
		if fade_time and fade_time > 0 then
			-- Start with volume at 0 and fade in
			current_soundscape:_SetTransitionVolume(0)
			current_soundscape:Activate()
			current_soundscape:_FadeIn(fade_time)
		else
			-- Ensure transition volume is 1 for instant activation
			current_soundscape:_SetTransitionVolume(1)
			current_soundscape:Activate()
		end
	end
end

return SoundscapeHandler
