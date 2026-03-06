--!strict

local Lighting = game:GetService("Lighting")
local current_scene_id: string? = nil

export type LightingData = {
	Lighting: {
		Ambient: Color3?,
		Brightness: number?,

		ColorShift_Bottom: Color3?,
		ColorShift_Top: Color3?,

		OutdoorAmbient: Color3?,
		ShadowSoftness: number?,

		GeographicLatitude: number?,
		ClockTime: number?,
		TimeOfDay: string?,

		FogEnd: number?,
		FogStart: number?,
		FogColor: Color3?,
	}?,
	Atmosphere: {
		Density: number?,
		Offset: number?,

		Color: Color3?,
		Decay: Color3?,
		Glare: number?,
		Haze: number?,
	}?,
	Sky: {
		CelestialBodiesShown: boolean?,
		MoonAngularSize: number?,
		MoonTextureId: string?,
		SunAngularSize: number?,
		SunTextureId: string?,
		StarCount: number?,

		SkyboxBk: string?,
		SkyboxDn: string?,
		SkyboxFt: string?,
		SkyboxLf: string?,
		SkyboxRt: string?,
		SkyboxUp: string?,
	}?,
	Clouds: {
		Cover: number?,
		Density: number?,
		Enabled: boolean?,
		Color: Color3?,
	}?,
	SunRaysEffect: {
		Intensity: number?,
		Spread: number?,
		Enabled: boolean?,
	}?,
	ColorCorrectionEffect: {
		Brightness: number?,
		Contrast: number?,
		Saturation: number?,
		TintColor: Color3?,
		Enabled: boolean?,
	}?,
	Workspace: {
		GlobalWind: Vector3?,
	}?,
}

--[=[
	A Lighting Scene represents a specific configuration of the Lighting service.
	It allows setting initial lighting data, a function to compute dynamic updates, and an update interval.
]=]
export type LightingScene = {
	--- A unique Id for this lighting scene
	Id: string,

	--[=[
		Sets the base lighting data for this scene. Use this to set any static properties of the scene.

		@param data A table of lighting data to set as the initial state.
	]=]
	SetInitialLighting: (self: LightingScene, data: LightingData) -> nil,
	--[=[
		Sets the function that computes new lighting data for this scene. This function will be called every update interval.

		@param computeFunction A function that returns a table of lighting data to update. Any properties not included in the returned table will be retained from the previous state.
	]=]
	SetLightingUpdater: (self: LightingScene, computeFunction: () -> LightingData) -> nil,

	--[=[
		Updates the cached lighting data and writes it to the Lighting service.

		@param only_update If true, only updates properties that have changed since the last update for performance. Defaults to false.
	]=]
	UpdateAndWriteData: (self: LightingScene, only_update: boolean?) -> nil,
	--- Gets the up-to-date lighting data for this scene
	GetCurrentLightingData: (self: LightingScene) -> LightingData,

	--- Returns whether this lighting scene is currently active.
	IsActive: (self: LightingScene) -> boolean,
}

type LightingScenePrivate = LightingScene & {
	--- The current lighting data from the last update
	_cache: LightingData,
	--- Function that computes some new lighting data. This is called every update interval. Any cached values not present in the returned table will be retained (only return what you want to change!)
	_computeFunction: () -> LightingData,

	--- Updates the internal cache with new data from the compute function, and returns a table of the changes made.
	_UpdateCache: (self: LightingScene) -> LightingData,
}

--- Writes the given properties table to the given lighting instance
local function write_to_instance(instance_type: string, properties_table: { [string]: any }?)
	local instance: Instance = nil
	local parent: Instance? = nil

	-- Finding the instance if it exists
	if instance_type == "Lighting" then
		instance = Lighting
	elseif instance_type == "Workspace" then
		instance = workspace
	elseif instance_type == "Clouds" then
		instance = workspace.Terrain:FindFirstChildOfClass("Clouds")
		parent = workspace.Terrain
	else
		instance = Lighting:FindFirstChildOfClass(instance_type)
		parent = Lighting
	end

	-- Updating the instance or destroying it if no properties are given
	if properties_table then
		if not instance then -- Creating the instance if it doesn't exist
			local success, result = pcall(Instance.new, instance_type)
			if not success then
				error(`LightingSceneService: Failed to create instance of type "{instance_type}": {result}`)
			end

			instance = result;
			(instance :: never).Parent = parent
		end

		for key, value in pairs(properties_table) do
			(instance :: never)[key] = value
		end
	else
		if instance and instance_type ~= "Lighting" and instance_type ~= "Workspace" then
			instance:Destroy()
		end
	end
end

local function write_lightingdata(data: LightingData)
	for instance_type, tab in pairs(data) do
		write_to_instance(instance_type, tab :: { [string]: any }?)
	end
end

local function clear_stale_instances(data: LightingData)
	local class_data: { [string]: { [string]: any }? } = {
		Atmosphere = data.Atmosphere :: { [string]: any }?,
		Sky = data.Sky :: { [string]: any }?,
		SunRaysEffect = data.SunRaysEffect :: { [string]: any }?,
		ColorCorrectionEffect = data.ColorCorrectionEffect :: { [string]: any }?,
		Clouds = data.Clouds :: { [string]: any }?,
	}

	for class_name, properties in pairs(class_data) do
		if properties == nil then
			write_to_instance(class_name, nil)
		end
	end
end

--[=[
	Performs a tween over a set duration, calling the update_function with an alpha value from 0 to 1.
	The update_function can return false to exit the tween early.

	@yields

	@param duration number -- The duration of the tween in seconds.
	@param update_function (number) -> boolean? -- A function that takes an alpha value (from 0 to 1) and performs any updates. If it returns false, the tween will exit early.
]=]
local function do_tween(duration: number, update_function: (number) -> boolean?)
	update_function(0)

	local start = os.clock()
	while true do
		task.wait()
		local delta = os.clock() - start
		local alpha = delta / duration
		if alpha >= 1 then
			break
		end

		local ret = update_function(alpha)
		if ret == false then
			return -- Early exit
		end
	end
	update_function(1)
end

--- Linearly interpolates between two LightingData tables based on alpha (0.0 - 1.0).
local function lerp_lightingdata(data_a: LightingData, data_b: LightingData, alpha: number): LightingData
	-- Finding all keys present in either data_a or data_b
	local key_map = {}
	for instance_type, tab in pairs(data_a) do
		key_map[instance_type] = {}

		for key, _ in pairs(tab) do
			key_map[instance_type][key] = true
		end
	end

	for instance_type, tab in pairs(data_b) do
		if not key_map[instance_type] then
			key_map[instance_type] = {}
		end

		for key, _ in pairs(tab) do
			key_map[instance_type][key] = true
		end
	end

	-- Interpolating values
	local result = {} :: LightingData
	for instance_type, key_map_for_type in pairs(key_map) do
		result[instance_type] = {}

		for key, _ in pairs(key_map_for_type) do
			local value_a = data_a[instance_type] and data_a[instance_type][key]
			local value_b = data_b[instance_type] and data_b[instance_type][key]

			-- Missing values
			if value_a == nil then
				result[instance_type][key] = value_b
				continue
			elseif value_b == nil then
				result[instance_type][key] = value_a
				continue
			end

			-- Type mismatch
			if typeof(value_a) ~= typeof(value_b) then
				error(
					string.format(
						"Cannot interpolate between different types at %s.%s: %s and %s",
						instance_type,
						key,
						typeof(value_a),
						typeof(value_b)
					)
				)
			end

			-- Interpolating based on type
			if typeof(value_a) == "number" then
				result[instance_type][key] = math.lerp(value_a, value_b, alpha)
			elseif typeof(value_a) == "Color3" or typeof(value_a) == "Vector3" then
				result[instance_type][key] = (value_a :: never):Lerp(value_b, alpha)
			else
				-- Unsupported type, step function
				result[instance_type][key] = if alpha < 0.5 then value_a else value_b
			end
		end
	end

	return result
end

-- Lighting Scene

--- Class representing a lighting scene
local LightingScene = {}
LightingScene.__index = LightingScene

function LightingScene.new(id: string): LightingScene
	local self = setmetatable({}, LightingScene)

	self.Id = id
	self._cache = {}

	self._computeFunction = function() -- Default to empty function
		return {}
	end

	return self :: never
end

function LightingScene.SetInitialLighting(self: LightingScenePrivate, data: LightingData)
	self._cache = data
end

function LightingScene.SetLightingUpdater(self: LightingScenePrivate, computeFunction: () -> LightingData)
	self._computeFunction = computeFunction
end

function LightingScene._UpdateCache(self: LightingScenePrivate)
	debug.profilebegin(`LightingScene computing update for scene "{self.Id}"`)
	local new_data = self._computeFunction()
	debug.profileend()

	-- Updating cache with new data
	for instance_type, tab in pairs(new_data) do
		if not self._cache[instance_type] then
			self._cache[instance_type] = {}
		end

		for key, value in pairs(tab) do
			self._cache[instance_type][key] = value
		end
	end

	return new_data
end

function LightingScene.UpdateAndWriteData(self: LightingScenePrivate, only_update: boolean?)
	local new_data = self:_UpdateCache()

	debug.profilebegin(`LightingScene writing to lighting for scene "{self.Id}"`)
	if only_update then -- Only write the new data
		write_lightingdata(new_data)
	else -- Write all data to the lighting
		write_lightingdata(self._cache)
	end
	debug.profileend()
end

function LightingScene.GetCurrentLightingData(self: LightingScenePrivate): LightingData
	self:_UpdateCache()
	return self._cache
end

function LightingScene.IsActive(self: LightingScenePrivate): boolean
	return current_scene_id == self.Id
end

--- Options for SetActive
type SetActiveOptions = {
	tweenTime: number?,
}

--- Lighting Scene Service - coordinates lighting scenes
local LightingSceneService = {}
LightingSceneService.Scene = LightingScene

local registered_scenes: { [string]: LightingScene } = {}

--- Registers a lighting scene with the service. The scene must have a unique Id.
LightingSceneService.Register = function(scene: LightingScene)
	if registered_scenes[scene.Id] then
		error(`LightingSceneService: Scene with Id "{scene.Id}" is already registered!`)
	end

	registered_scenes[scene.Id] = scene
end

--- Registers all lighting scenes in the given folder. Each child module must return a LightingScene.
LightingSceneService.RegisterFromFolder = function(folder: Instance)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local scene_module = require(child) :: LightingScene
			LightingSceneService.Register(scene_module)
		end
	end
end

--- Gets a registered lighting scene by its Id. Returns nil if no scene with the given Id is registered.
LightingSceneService.Get = function(id: string): LightingScene?
	return registered_scenes[id]
end

--- Helper function to clear all lighting-related instances from the datamodel.
LightingSceneService.ClearLighting = function()
	Lighting:ClearAllChildren()

	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds:Destroy()
	end
end

local last_lighting_changed = 0
local current_active_scene: LightingScene? = nil

--- Sets the active lighting scene, deactivating any previously active scene.
LightingSceneService.SetActive = function(id: string?, options: SetActiveOptions?)
	if id and not registered_scenes[id] then
		error(`LightingSceneService: Scene with Id "{id}" is not registered!`)
	end

	if id == current_scene_id then
		-- Already active, do nothing
		return
	end

	local my_timestamp = os.clock()
	local tween_time = options and options.tweenTime

	last_lighting_changed = my_timestamp
	current_scene_id = id

	if not id then
		LightingSceneService.ClearLighting()
		current_active_scene = nil
		return
	end

	-- Start update loop
	local target_scene = registered_scenes[id]
	local old_scene = current_active_scene
	local should_tween = old_scene ~= nil and tween_time ~= nil and tween_time > 0

	current_active_scene = target_scene

	if not should_tween then
		LightingSceneService.ClearLighting()
	end

	task.spawn(function()
		-- Initial lerp
		if should_tween and old_scene and tween_time then
			do_tween(tween_time, function(alpha)
				if last_lighting_changed ~= my_timestamp then
					-- Scene changed during lerp, abort
					return false
				end

				-- Lerp between old and new scene
				local lerped_data = lerp_lightingdata(
					old_scene:GetCurrentLightingData(),
					target_scene:GetCurrentLightingData(),
					alpha
				)

				write_lightingdata(lerped_data)

				return true
			end)
		end

		if last_lighting_changed ~= my_timestamp then
			-- Scene changed during lerp, abort
			return
		end

		-- Final write to ensure exact values
		target_scene:UpdateAndWriteData(false)
		clear_stale_instances(target_scene:GetCurrentLightingData())

		-- Updating loop
		while last_lighting_changed == my_timestamp do
			target_scene:UpdateAndWriteData(true)
			task.wait(1)
		end
	end)
end

--- Gets the currently active lighting scene, or nil if no scene is active.
LightingSceneService.GetActive = function(): LightingScene?
	if current_scene_id then
		return registered_scenes[current_scene_id]
	else
		return nil
	end
end

return LightingSceneService
