--!strict
local Lighting = game:GetService("Lighting")

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

		-- Textures are non-optional because skyboxes are useless without them. Avoiding a footgun!
		SkyboxBk: string,
		SkyboxDn: string,
		SkyboxFt: string,
		SkyboxLf: string,
		SkyboxRt: string,
		SkyboxUp: string,
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

export type ValueOrFn<T> = T | ((T) -> T)

type ResolveProps = { [string]: ValueOrFn<any>? }

export type ResolvableLightingData = {
	Lighting: ResolveProps?,
	Atmosphere: ResolveProps?,
	Sky: ResolveProps?,
	Clouds: ResolveProps?,
	SunRaysEffect: ResolveProps?,
	ColorCorrectionEffect: ResolveProps?,
	Workspace: ResolveProps?,
}

local ROBLOX_DEFAULTS: ResolvableLightingData = {
	Lighting = {
		Ambient = Color3.fromRGB(0, 0, 0),
		Brightness = 1,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(128, 128, 128),
		ShadowSoftness = 0.2,
		GeographicLatitude = 41.733,
		ClockTime = 14,
		FogEnd = 100000,
		FogStart = 0,
		FogColor = Color3.fromRGB(192, 192, 192),
	},
	Atmosphere = {
		Density = 0,
		Offset = 0,
		Color = Color3.fromRGB(215, 255, 255),
		Decay = Color3.fromRGB(92, 60, 13),
		Glare = 0,
		Haze = 0,
	},
	Sky = {
		CelestialBodiesShown = true,
		MoonAngularSize = 11,
		MoonTextureId = "rbxassetid://6444320592",
		SunAngularSize = 21,
		SunTextureId = "rbxassetid://6444320512",
		StarCount = 3000,
		SkyboxBk = "rbxassetid://6444884337",
		SkyboxDn = "rbxassetid://6444884785",
		SkyboxFt = "rbxassetid://6444884337",
		SkyboxLf = "rbxassetid://6444884337",
		SkyboxRt = "rbxassetid://6444884337",
		SkyboxUp = "rbxassetid://6444884337",
	},
	Clouds = {
		Cover = 0.5,
		Density = 0.7,
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
	},
	SunRaysEffect = {
		Intensity = 0.25,
		Spread = 1,
		Enabled = true,
	},
	ColorCorrectionEffect = {
		Brightness = 0,
		Contrast = 0,
		Saturation = 0,
		TintColor = Color3.fromRGB(255, 255, 255),
		Enabled = true,
	},
	Workspace = {
		GlobalWind = Vector3.zero,
	},
}

local INSTANCE_CLASSES = { "Atmosphere", "Sky", "SunRaysEffect", "ColorCorrectionEffect", "Clouds" }

local function write_to_instance(instance_type: string, properties_table: { [string]: any }?)
	local instance: Instance = nil
	local parent: Instance? = nil

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

	if properties_table then
		if not instance then
			local success, result = pcall(Instance.new, instance_type)
			if not success then
				error(`Lighting: Failed to create instance of type "{instance_type}": {result}`)
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
	for _, class_name in ipairs(INSTANCE_CLASSES) do
		if (data :: any)[class_name] == nil then
			write_to_instance(class_name, nil)
		end
	end
end

local function clear_lighting()
	Lighting:ClearAllChildren()
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds:Destroy()
	end
end

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
			return
		end
	end
	update_function(1)
end

local function lerp_lightingdata(data_a: LightingData, data_b: LightingData, alpha: number): LightingData
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

	local result = {} :: LightingData
	for instance_type, key_map_for_type in pairs(key_map) do
		result[instance_type] = {}

		for key, _ in pairs(key_map_for_type) do
			local value_a = data_a[instance_type] and data_a[instance_type][key]
			local value_b = data_b[instance_type] and data_b[instance_type][key]

			if value_a == nil then
				result[instance_type][key] = value_b
				continue
			elseif value_b == nil then
				result[instance_type][key] = value_a
				continue
			end

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

			if typeof(value_a) == "number" then
				result[instance_type][key] = math.lerp(value_a, value_b, alpha)
			elseif typeof(value_a) == "Color3" or typeof(value_a) == "Vector3" then
				result[instance_type][key] = (value_a :: never):Lerp(value_b, alpha)
			else
				result[instance_type][key] = if alpha < 0.5 then value_a else value_b
			end
		end
	end

	return result
end

local function selective_lerp_lightingdata(
	data_a: LightingData,
	data_b: LightingData,
	alpha: number,
	transition_keys: { [string]: { [string]: true } }?
): LightingData
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

	local result = {} :: LightingData
	for instance_type, key_map_for_type in pairs(key_map) do
		result[instance_type] = {}

		for key, _ in pairs(key_map_for_type) do
			local value_a = data_a[instance_type] and data_a[instance_type][key]
			local value_b = data_b[instance_type] and data_b[instance_type][key]

			local should_lerp = transition_keys == nil
				or (transition_keys[instance_type] ~= nil and transition_keys[instance_type][key] == true)

			if not should_lerp then
				if value_b ~= nil then
					result[instance_type][key] = value_b
				elseif value_a ~= nil then
					result[instance_type][key] = value_a
				end
				continue
			end

			if value_a == nil then
				result[instance_type][key] = value_b
				continue
			elseif value_b == nil then
				result[instance_type][key] = value_a
				continue
			end

			if typeof(value_a) ~= typeof(value_b) then
				result[instance_type][key] = if alpha < 0.5 then value_a else value_b
				continue
			end

			if typeof(value_a) == "number" then
				result[instance_type][key] = math.lerp(value_a, value_b, alpha)
			elseif typeof(value_a) == "Color3" or typeof(value_a) == "Vector3" then
				result[instance_type][key] = (value_a :: never):Lerp(value_b, alpha)
			else
				result[instance_type][key] = if alpha < 0.5 then value_a else value_b
			end
		end
	end

	return result
end

local function resolve_lighting(layers: { ResolvableLightingData }): (LightingData, boolean)
	local effective_defaults: ResolvableLightingData = {
		Lighting = ROBLOX_DEFAULTS.Lighting,
		Workspace = ROBLOX_DEFAULTS.Workspace,
	}
	for _, layer in ipairs(layers) do
		for group_name, props in pairs(layer) do
			if
				props ~= nil
				and (ROBLOX_DEFAULTS :: any)[group_name] ~= nil
				and (effective_defaults :: any)[group_name] == nil
			then
				(effective_defaults :: any)[group_name] = (ROBLOX_DEFAULTS :: any)[group_name]
			end
		end
	end

	local all_layers = table.clone(layers)
	table.insert(all_layers, effective_defaults)

	local key_map: { [string]: { [string]: boolean } } = {}
	for _, layer in ipairs(all_layers) do
		for instance_type, properties in pairs(layer) do
			if properties ~= nil then
				if not key_map[instance_type] then
					key_map[instance_type] = {}
				end
				for key, value in pairs(properties) do
					if value ~= nil then
						key_map[instance_type][key] = true
					end
				end
			end
		end
	end

	local resolved = {} :: LightingData
	local has_dynamic = false

	for instance_type, keys in pairs(key_map) do
		for key, _ in pairs(keys) do
			local modifiers: { (any) -> any } = {}
			local base_value: any = nil

			for _, layer in ipairs(all_layers) do
				local properties = layer[instance_type]
				local raw_value = properties and properties[key]
				if raw_value ~= nil then
					if typeof(raw_value) == "function" then
						has_dynamic = true
						table.insert(modifiers, raw_value :: (any) -> any)
					else
						base_value = raw_value
						break
					end
				end
			end

			local current = base_value
			for index = #modifiers, 1, -1 do
				local ok, result = pcall(modifiers[index], current)
				if not ok then
					warn(`Lighting modifier failed at {instance_type}.{key}: {result}`)
				else
					current = result
				end
			end

			if current ~= nil then
				if not resolved[instance_type] then
					resolved[instance_type] = {}
				end
				resolved[instance_type][key] = current
			end
		end
	end

	return resolved, has_dynamic
end

return {
	resolve_lighting = resolve_lighting,
	write_lightingdata = write_lightingdata,
	clear_stale_instances = clear_stale_instances,
	clear_lighting = clear_lighting,
	do_tween = do_tween,
	lerp_lightingdata = lerp_lightingdata,
	selective_lerp_lightingdata = selective_lerp_lightingdata,
}
