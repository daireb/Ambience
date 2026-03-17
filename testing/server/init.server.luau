--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ambience = require(ReplicatedStorage.Package)

-- Test runner ----------------------------------------------------------------

local passed, failed = 0, 0

local function test(name: string, fn: () -> ())
	Ambience.clear()

	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print(`  PASS  {name}`)
	else
		failed += 1
		warn(`  FAIL  {name}: {err}`)
	end
end

local function assertEqual(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "assertEqual"}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

local function assertApprox(actual: number, expected: number, label: string?, tolerance: number?)
	local tol = tolerance or 0.001
	if math.abs(actual - expected) > tol then
		error(`{label or "assertApprox"}: expected ~{expected}, got {actual}`)
	end
end

local function assertNil(value: any, label: string?)
	if value ~= nil then
		error(`{label or "assertNil"}: expected nil, got {tostring(value)}`)
	end
end

local function assertNotNil(value: any, label: string?)
	if value == nil then
		error(`{label or "assertNotNil"}: expected non-nil value`)
	end
end

-- Test presets ----------------------------------------------------------------

Ambience.register("Base", Ambience.preset({
	priority = 0,
	lighting = {
		Lighting = {
			Brightness = 3,
			Ambient = Color3.fromRGB(150, 150, 150),
			ClockTime = 12,
		},
		Atmosphere = {
			Density = 0.3,
			Haze = 1,
			Color = Color3.fromRGB(199, 216, 255),
		},
		Sky = {
			CelestialBodiesShown = true,
			StarCount = 3000,
			SkyboxBk = "rbxassetid://6444884337",
			SkyboxDn = "rbxassetid://6444884785",
			SkyboxFt = "rbxassetid://6444884337",
			SkyboxLf = "rbxassetid://6444884337",
			SkyboxRt = "rbxassetid://6444884337",
			SkyboxUp = "rbxassetid://6444884337",
		},
		ColorCorrectionEffect = {
			Brightness = 0.1,
			Contrast = 0.2,
			Saturation = 0.15,
			TintColor = Color3.fromRGB(255, 240, 220),
			Enabled = true,
		},
	},
}))

Ambience.register("Overlay", Ambience.preset({
	priority = 10,
	lighting = {
		Lighting = {
			Brightness = function(current: number)
				return current * 0.5
			end,
		},
		Atmosphere = {
			Density = function(current: number)
				return current + 0.1
			end,
		},
	},
}))

Ambience.register("PartialCC", Ambience.preset({
	priority = 0,
	lighting = {
		ColorCorrectionEffect = {
			Brightness = 0.3,
			Enabled = true,
		},
	},
}))

Ambience.register("BareMin", Ambience.preset({
	priority = 0,
	lighting = {
		Lighting = {
			Brightness = 2,
			Ambient = Color3.fromRGB(80, 80, 80),
		},
	},
}))

Ambience.register("HighPri", Ambience.preset({
	priority = 20,
	lighting = {
		Lighting = {
			Brightness = 10,
		},
	},
}))

Ambience.register("ModA", Ambience.preset({
	priority = 5,
	lighting = {
		Lighting = {
			Brightness = function(current: number)
				return current + 2
			end,
		},
	},
}))

Ambience.register("ModB", Ambience.preset({
	priority = 15,
	lighting = {
		Lighting = {
			Brightness = function(current: number)
				return current * 3
			end,
		},
	},
}))

Ambience.register("SoundOnly", Ambience.preset({
	priority = 0,
}))

Ambience.register("NoPriority", Ambience.preset({
	lighting = {
		Lighting = {
			Brightness = 7,
		},
	},
}))

-- Tests ----------------------------------------------------------------------

print("\n=== Ambience Test Suite ===\n")

test("clear state: service properties resolve to Roblox defaults", function()
	assertEqual(Ambience.query("Lighting", "Brightness"), 1, "Brightness")
	assertEqual(Ambience.query("Lighting", "ClockTime"), 14, "ClockTime")
	assertEqual(Ambience.query("Lighting", "FogEnd"), 100000, "FogEnd")
	assertApprox(Ambience.query("Lighting", "ShadowSoftness"), 0.2, "ShadowSoftness")
	assertEqual(Ambience.query("Workspace", "GlobalWind"), Vector3.zero, "GlobalWind")
end)

test("clear state: instance groups return nil", function()
	assertNil(Ambience.query("Sky"), "Sky")
	assertNil(Ambience.query("Atmosphere"), "Atmosphere")
	assertNil(Ambience.query("Clouds"), "Clouds")
	assertNil(Ambience.query("SunRaysEffect"), "SunRaysEffect")
	assertNil(Ambience.query("ColorCorrectionEffect"), "ColorCorrectionEffect")
end)

test("push: properties resolve to preset values", function()
	Ambience.push("Base")
	assertEqual(Ambience.query("Lighting", "Brightness"), 3, "Brightness")
	assertEqual(Ambience.query("Lighting", "ClockTime"), 12, "ClockTime")
	assertApprox(Ambience.query("Atmosphere", "Density"), 0.3, "Density")
	assertEqual(Ambience.query("Sky", "StarCount"), 3000, "StarCount")
end)

test("pop: properties revert to defaults", function()
	Ambience.push("Base")
	assertEqual(Ambience.query("Lighting", "Brightness"), 3, "before pop")
	Ambience.pop("Base")
	assertEqual(Ambience.query("Lighting", "Brightness"), 1, "after pop")
	assertNil(Ambience.query("Sky"), "Sky after pop")
	assertNil(Ambience.query("Atmosphere"), "Atmosphere after pop")
end)

test("set: swaps to new preset, removes old groups", function()
	Ambience.set("Base")
	assertNotNil(Ambience.query("Sky"), "Sky with Base")
	assertNotNil(Ambience.query("Atmosphere"), "Atmosphere with Base")

	Ambience.set("BareMin")
	assertEqual(Ambience.query("Lighting", "Brightness"), 2, "BareMin Brightness")
	assertNil(Ambience.query("Sky"), "Sky after set BareMin")
	assertNil(Ambience.query("Atmosphere"), "Atmosphere after set BareMin")
	assertNil(Ambience.query("ColorCorrectionEffect"), "CC after set BareMin")
end)

test("clear: reverts all to defaults", function()
	Ambience.push("Base")
	Ambience.push("Overlay")
	Ambience.clear()
	assertEqual(Ambience.query("Lighting", "Brightness"), 1, "Brightness")
	assertNil(Ambience.query("Sky"), "Sky")
	assertEqual(#Ambience.getActive(), 0, "active count")
end)

test("modifier: receives real base value from lower layer", function()
	Ambience.push("Base")
	Ambience.push("Overlay")
	assertApprox(Ambience.query("Lighting", "Brightness"), 3 * 0.5, "Brightness = 3 * 0.5")
	assertApprox(Ambience.query("Atmosphere", "Density"), 0.3 + 0.1, "Density = 0.3 + 0.1")
end)

test("modifier: receives Roblox default when no fixed base in real layers", function()
	Ambience.push("Overlay")
	assertApprox(Ambience.query("Lighting", "Brightness"), 1 * 0.5, "Brightness = default 1 * 0.5")
	assertApprox(Ambience.query("Atmosphere", "Density"), 0 + 0.1, "Density = default 0 + 0.1")
end)

test("partial group: omitted properties resolve to Roblox defaults", function()
	Ambience.push("PartialCC")
	assertApprox(Ambience.query("ColorCorrectionEffect", "Brightness"), 0.3, "Brightness set")
	assertEqual(Ambience.query("ColorCorrectionEffect", "Enabled"), true, "Enabled set")
	assertApprox(Ambience.query("ColorCorrectionEffect", "Contrast"), 0, "Contrast default")
	assertApprox(Ambience.query("ColorCorrectionEffect", "Saturation"), 0, "Saturation default")
	assertEqual(
		Ambience.query("ColorCorrectionEffect", "TintColor"),
		Color3.fromRGB(255, 255, 255),
		"TintColor default"
	)
end)

test("partial group: no stale values from previous preset", function()
	Ambience.push("Base")
	assertApprox(Ambience.query("ColorCorrectionEffect", "Saturation"), 0.15, "Saturation from Base")
	Ambience.pop("Base")
	Ambience.push("PartialCC")
	assertApprox(Ambience.query("ColorCorrectionEffect", "Saturation"), 0, "Saturation after swap")
end)

test("instance group absence: BareMin has no instance groups", function()
	Ambience.push("BareMin")
	assertNil(Ambience.query("Sky"), "Sky")
	assertNil(Ambience.query("Atmosphere"), "Atmosphere")
	assertNil(Ambience.query("Clouds"), "Clouds")
	assertNil(Ambience.query("ColorCorrectionEffect"), "ColorCorrectionEffect")
	assertNil(Ambience.query("SunRaysEffect"), "SunRaysEffect")
end)

test("service defaults still present with BareMin", function()
	Ambience.push("BareMin")
	assertEqual(Ambience.query("Lighting", "Brightness"), 2, "Brightness from BareMin")
	assertEqual(Ambience.query("Lighting", "FogEnd"), 100000, "FogEnd from default")
	assertEqual(Ambience.query("Lighting", "ClockTime"), 14, "ClockTime from default")
end)

test("query: single property returns value", function()
	Ambience.push("Base")
	local brightness = Ambience.query("Lighting", "Brightness")
	assertEqual(typeof(brightness), "number", "type")
	assertEqual(brightness, 3, "value")
end)

test("query: group returns table", function()
	Ambience.push("Base")
	local lighting = Ambience.query("Lighting")
	assertEqual(typeof(lighting), "table", "type")
	assertNotNil(lighting.Brightness, "has Brightness")
	assertNotNil(lighting.ClockTime, "has ClockTime")
	assertNotNil(lighting.FogEnd, "has FogEnd")
end)

test("query: nonexistent group returns nil", function()
	assertNil(Ambience.query("FakeGroup"), "FakeGroup")
	assertNil(Ambience.query("Lighting", "FakeProperty"), "FakeProperty")
end)

test("priority: higher priority layer overrides lower", function()
	Ambience.push("Base")
	Ambience.push("HighPri")
	assertEqual(Ambience.query("Lighting", "Brightness"), 10, "HighPri wins")
end)

test("priority: popping high priority reveals lower", function()
	Ambience.push("Base")
	Ambience.push("HighPri")
	assertEqual(Ambience.query("Lighting", "Brightness"), 10, "HighPri active")
	Ambience.pop("HighPri")
	assertEqual(Ambience.query("Lighting", "Brightness"), 3, "Base revealed")
end)

test("isActive: reflects push/pop state", function()
	assertEqual(Ambience.isActive("Base"), false, "before push")
	Ambience.push("Base")
	assertEqual(Ambience.isActive("Base"), true, "after push")
	Ambience.pop("Base")
	assertEqual(Ambience.isActive("Base"), false, "after pop")
end)

test("getActive: returns active ids in priority order", function()
	Ambience.push("Base")
	Ambience.push("Overlay")
	local active = Ambience.getActive()
	assertEqual(active[1], "Overlay", "first = highest priority")
	assertEqual(active[2], "Base", "second = lower priority")
	assertEqual(#active, 2, "count")
end)

test("push: duplicate push is no-op", function()
	Ambience.push("Base")
	Ambience.push("Base")
	assertEqual(#Ambience.getActive(), 1, "still one layer")
end)

test("pop: unknown id is no-op", function()
	Ambience.push("Base")
	Ambience.pop("NonExistent")
	assertEqual(#Ambience.getActive(), 1, "still one layer")
end)

test("modifier chain: multiple modifiers applied bottom-up", function()
	-- Base(pri=0): Brightness=3, ModA(pri=5): +2, ModB(pri=15): *3
	-- Resolution: base=3 -> ModA(3)=5 -> ModB(5)=15
	Ambience.push("Base")
	Ambience.push("ModA")
	Ambience.push("ModB")
	assertApprox(Ambience.query("Lighting", "Brightness"), (3 + 2) * 3, "3 -> +2 -> *3 = 15")
end)

test("modifier chain: order matters (not commutative)", function()
	-- Without ModA: base=3 -> ModB(3)=9
	Ambience.push("Base")
	Ambience.push("ModB")
	assertApprox(Ambience.query("Lighting", "Brightness"), 3 * 3, "3 -> *3 = 9")
end)

test("error: push unregistered id", function()
	local ok, err = pcall(function()
		Ambience.push("DoesNotExist")
	end)
	assertEqual(ok, false, "should error")
	assertNotNil(string.find(err :: string, "DoesNotExist"), "error mentions id")
end)

test("error: register duplicate id", function()
	local ok, err = pcall(function()
		Ambience.register("Base", Ambience.preset({ priority = 0 }))
	end)
	assertEqual(ok, false, "should error")
	assertNotNil(string.find(err :: string, "Base"), "error mentions id")
end)

test("no-lighting preset: doesn't break resolution", function()
	Ambience.push("Base")
	Ambience.push("SoundOnly")
	assertEqual(Ambience.query("Lighting", "Brightness"), 3, "Base Brightness unaffected")
	assertNotNil(Ambience.query("Sky"), "Sky still present from Base")
	assertEqual(#Ambience.getActive(), 2, "both active")
end)

test("no-lighting preset: alone resolves to defaults", function()
	Ambience.push("SoundOnly")
	assertEqual(Ambience.query("Lighting", "Brightness"), 1, "default Brightness")
	assertNil(Ambience.query("Sky"), "no Sky")
end)

test("set: idempotent when already sole active", function()
	Ambience.set("Base")
	Ambience.set("Base")
	assertEqual(#Ambience.getActive(), 1, "still one layer")
	assertEqual(Ambience.getActive()[1], "Base", "still Base")
	assertEqual(Ambience.query("Lighting", "Brightness"), 3, "values unchanged")
end)

test("default priority: omitted priority treated as 0", function()
	Ambience.push("NoPriority")
	assertEqual(Ambience.query("Lighting", "Brightness"), 7, "NoPriority value")
	Ambience.push("HighPri")
	assertEqual(Ambience.query("Lighting", "Brightness"), 10, "HighPri overrides")
end)

-- Summary --------------------------------------------------------------------

print(`\n=== Results: {passed} passed, {failed} failed ===\n`)

if failed > 0 then
	warn("Some tests failed!")
end
