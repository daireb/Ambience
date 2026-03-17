--!strict
local LightingModule = require(script.Lighting)
local TrackModule = require(script.Track)

type Track = TrackModule.Track
type LightingData = LightingModule.LightingData
type ResolvableLightingData = LightingModule.ResolvableLightingData

export type Preset = {
	priority: number?,
	lighting: ResolvableLightingData?,
	sounds: { Track }?,
}

type LayerState = {
	id: string,
	preset: Preset,
	fadeToken: number,
}

type TransitionOptions = {
	transition: number?,
}

local presets: { [string]: Preset } = {}
local active_layers: { LayerState } = {}

local lighting_transition_token = 0
local current_lighting_state: LightingData = {}

local function get_priority(preset: Preset): number
	return preset.priority or 0
end

local function sort_active_layers()
	table.sort(active_layers, function(a, b)
		return get_priority(a.preset) > get_priority(b.preset)
	end)
end

local function set_layer_tracks_volume(layer: LayerState, volume: number)
	local sounds = layer.preset.sounds
	if not sounds then
		return
	end
	for _, track in ipairs(sounds) do
		(track :: any):_SetTransitionVolume(volume)
	end
end

local function fade_layer_tracks(
	layer: LayerState,
	from_volume: number,
	to_volume: number,
	duration: number,
	stop_after: boolean
)
	local sounds = layer.preset.sounds
	if not sounds then
		return
	end

	layer.fadeToken += 1
	local my_token = layer.fadeToken

	if duration <= 0 then
		set_layer_tracks_volume(layer, to_volume)
		if stop_after then
			for _, track in ipairs(sounds) do
				track:Stop()
			end
		end
		return
	end

	task.spawn(function()
		local start_time = os.clock()
		while os.clock() - start_time < duration do
			if layer.fadeToken ~= my_token then
				return
			end
			local alpha = (os.clock() - start_time) / duration
			local volume = from_volume + (to_volume - from_volume) * alpha
			set_layer_tracks_volume(layer, volume)
			task.wait()
		end

		if layer.fadeToken ~= my_token then
			return
		end

		set_layer_tracks_volume(layer, to_volume)
		if stop_after then
			for _, track in ipairs(sounds) do
				track:Stop()
			end
		end
	end)
end

local function collect_lighting_layers(): { ResolvableLightingData }
	local layers = {}
	for _, layer in ipairs(active_layers) do
		if layer.preset.lighting then
			table.insert(layers, layer.preset.lighting :: ResolvableLightingData)
		end
	end
	return layers
end

local function write_lighting_snapshot(data: LightingData)
	if #active_layers == 0 then
		LightingModule.clear_lighting()
	end
	LightingModule.write_lightingdata(data)
	LightingModule.clear_stale_instances(data)
end

local function get_lighting_keys(p: Preset): { [string]: { [string]: true } }?
	if not p.lighting then
		return nil
	end
	local keys: { [string]: { [string]: true } } = {}
	for instance_type, properties in pairs(p.lighting) do
		if properties then
			keys[instance_type] = {}
			for key, _ in pairs(properties) do
				keys[instance_type][key] = true
			end
		end
	end
	return keys
end

local function start_dynamic_loop(token: number)
	task.spawn(function()
		while lighting_transition_token == token do
			task.wait()
			local resolved, still_dynamic = LightingModule.resolve_lighting(collect_lighting_layers())
			LightingModule.write_lightingdata(resolved)
			LightingModule.clear_stale_instances(resolved)
			current_lighting_state = resolved
			if not still_dynamic then
				return
			end
		end
	end)
end

local function refresh_lighting(transition: number?, transition_keys: { [string]: { [string]: true } }?)
	lighting_transition_token += 1
	local my_token = lighting_transition_token
	local duration = transition or 0

	local new_resolved, new_dynamic = LightingModule.resolve_lighting(collect_lighting_layers())

	if duration <= 0 or next(current_lighting_state) == nil then
		write_lighting_snapshot(new_resolved)
		current_lighting_state = new_resolved
		if new_dynamic then
			start_dynamic_loop(my_token)
		end
		return
	end

	local from_snapshot = current_lighting_state

	task.spawn(function()
		local start_time = os.clock()
		while os.clock() - start_time < duration do
			if lighting_transition_token ~= my_token then
				return
			end

			local alpha = (os.clock() - start_time) / duration
			local target = LightingModule.resolve_lighting(collect_lighting_layers())
			local frame = LightingModule.selective_lerp_lightingdata(from_snapshot, target, alpha, transition_keys)

			LightingModule.write_lightingdata(frame)
			current_lighting_state = frame
			task.wait()
		end

		if lighting_transition_token ~= my_token then
			return
		end

		local final, final_dynamic = LightingModule.resolve_lighting(collect_lighting_layers())
		write_lighting_snapshot(final)
		current_lighting_state = final
		if final_dynamic then
			start_dynamic_loop(my_token)
		end
	end)
end

local function add_layer(id: string, preset: Preset, transition: number)
	local layer: LayerState = {
		id = id,
		preset = preset,
		fadeToken = 0,
	}
	table.insert(active_layers, layer)
	sort_active_layers()

	local sounds = preset.sounds
	if sounds then
		if transition > 0 then
			set_layer_tracks_volume(layer, 0)
		else
			set_layer_tracks_volume(layer, 1)
		end
		for _, track in ipairs(sounds) do
			track:Activate()
		end
		if transition > 0 then
			fade_layer_tracks(layer, 0, 1, transition, false)
		end
	end
end

local function remove_layer_at(index: number, transition: number)
	local layer = active_layers[index]
	table.remove(active_layers, index)

	if layer.preset.sounds then
		if transition > 0 then
			fade_layer_tracks(layer, 1, 0, transition, true)
		else
			for _, track in ipairs(layer.preset.sounds :: { Track }) do
				track:Stop()
			end
		end
	end
end

local function find_active_layer_index(id: string): number?
	for index, layer in ipairs(active_layers) do
		if layer.id == id then
			return index
		end
	end
	return nil
end

local function preset(p: Preset): Preset
	return p
end

local function register(id: string, value: Preset)
	if presets[id] then
		error(`Ambience: Preset "{id}" is already registered`)
	end
	presets[id] = value
end

local function registerFromFolder(folder: Instance)
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("ModuleScript") then
			local preset_module = require(child) :: Preset
			register(child.Name, preset_module)
		end
	end
end

local function push(id: string, options: TransitionOptions?)
	local preset_data = presets[id]
	if not preset_data then
		error(`Ambience: No preset registered with id "{id}"`)
	end
	if find_active_layer_index(id) then
		return
	end

	local transition = options and options.transition or 0
	add_layer(id, preset_data, transition)
	refresh_lighting(transition, get_lighting_keys(preset_data))
end

local function pop(id: string, options: TransitionOptions?)
	local index = find_active_layer_index(id)
	if not index then
		return
	end

	local transition = options and options.transition or 0
	local layer_preset = active_layers[index].preset
	local keys = get_lighting_keys(layer_preset)
	remove_layer_at(index, transition)
	refresh_lighting(transition, keys)
end

local function clear(options: TransitionOptions?)
	local transition = options and options.transition or 0
	while #active_layers > 0 do
		remove_layer_at(1, transition)
	end
	refresh_lighting(transition, nil)
end

local function set(id: string, options: TransitionOptions?)
	local transition = options and options.transition or 0
	for index = #active_layers, 1, -1 do
		if active_layers[index].id ~= id then
			remove_layer_at(index, transition)
		end
	end
	if not find_active_layer_index(id) then
		local preset_data = presets[id]
		if not preset_data then
			error(`Ambience: No preset registered with id "{id}"`)
		end
		add_layer(id, preset_data, transition)
	end
	refresh_lighting(transition, nil)
end

local function isActive(id: string): boolean
	return find_active_layer_index(id) ~= nil
end

local function getActive(): { string }
	local ids = {}
	for _, layer in ipairs(active_layers) do
		table.insert(ids, layer.id)
	end
	return ids
end

local function query(group: string, property: string?): any
	local resolved = LightingModule.resolve_lighting(collect_lighting_layers())
	local group_data = (resolved :: any)[group]
	if property then
		return group_data and group_data[property]
	end
	return group_data
end

return {
	register = register,
	registerFromFolder = registerFromFolder,
	push = push,
	pop = pop,
	set = set,
	clear = clear,
	isActive = isActive,
	getActive = getActive,
	query = query,
	preset = preset,
	Track = TrackModule,
}
