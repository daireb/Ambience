# Ambience

A layered ambient lighting and sound system for Roblox.

Define presets that combine lighting properties and sound tracks, then push, pop, and
blend them at runtime. Higher-priority layers override lower ones per-property for
lighting, while sounds from all active layers play simultaneously.

## Install

```bash
pesde add gh#daireb/Ambience#v0.2.0
```

## Quick start

```lua
local Ambience = require(path.to.Ambience)

-- Load every ModuleScript preset under a folder (id = ModuleScript.Name)
Ambience.registerFromFolder(script.presets)

-- Swap to a single preset (pops everything else)
Ambience.set("Day", { transition = 2 })

-- Or layer presets on top of each other
Ambience.push("Forest", { transition = 1 })
Ambience.push("Rain", { transition = 3 })

-- Remove a layer
Ambience.pop("Rain", { transition = 5 })

-- Remove all layers
Ambience.clear({ transition = 1 })
```

## Writing presets

A preset is a ModuleScript that returns a table with optional `priority`, `lighting`,
and `sounds` fields. Wrap the return in `Ambience.preset()` for editor autocomplete.

### Lighting-only preset

```lua
-- presets/Day.luau
local Ambience = require(ReplicatedStorage.Package)

return Ambience.preset({
    priority = 0,
    lighting = {
        Lighting = {
            Brightness = 3,
            Ambient = Color3.fromRGB(150, 150, 150),
            ClockTime = 14,
        },
        Atmosphere = {
            Density = 0.3,
            Color = Color3.fromRGB(199, 216, 255),
        },
        Sky = { CelestialBodiesShown = true, StarCount = 3000 },
        Clouds = { Cover = 0.5, Enabled = true },
        SunRaysEffect = { Intensity = 0.1, Spread = 0.8, Enabled = true },
    },
})
```

### Sound-only preset

```lua
-- presets/Forest.luau
local Ambience = require(ReplicatedStorage.Package)
local Track = Ambience.Track

local birds = Instance.new("Sound")
birds.SoundId = "rbxassetid://9116971174"
birds.Volume = 0.4
birds.Looped = true

return Ambience.preset({
    priority = 0,
    sounds = {
        Track.looping(birds):ModifyVolume(0.6):AutoFadeInOut(2),
    },
})
```

### Combined preset with modifiers

```lua
-- presets/Rain.luau  (priority 10, modifies brightness relative to base)
local Ambience = require(ReplicatedStorage.Package)
local Track = Ambience.Track

local rain = Instance.new("Sound")
rain.SoundId = "rbxassetid://9064263922"
rain.Volume = 0.5
rain.Looped = true

return Ambience.preset({
    priority = 10,
    lighting = {
        Lighting = {
            FogEnd = 1800,
            Brightness = function(current) return current * 0.5 end,
        },
        Atmosphere = {
            Density = function(current) return current + 0.15 end,
            Haze = function(current) return current * 1.5 end,
        },
    },
    sounds = {
        Track.looping(rain):ModifyVolume(0.7):AutoFadeInOut(3),
    },
})
```

### Dynamic and modifier lighting values

Any lighting property can be a function instead of a static value. Functions are
evaluated every frame while the layer is active, and receive the current built-up
value for that property.

```lua
return Ambience.preset({
    priority = 10,
    lighting = {
        Lighting = {
            -- Modifier: darken whatever lower-priority layers set.
            Brightness = function(current)
                return current * 0.5
            end,

            -- Dynamic absolute value: ignore the current value.
            ClockTime = function(_current)
                return workspace:GetServerTimeNow() % 24
            end,
        },
    },
})
```

If no lower-priority fixed value exists for a property, modifier functions receive
the Roblox Studio default for that property (see [How layering works](#how-layering-works)).

## API

### `Ambience.register(id: string, preset: Preset)`

Register a preset manually with a given id.

### `Ambience.registerFromFolder(folder: Instance)`

Require every descendant ModuleScript and register each one using
`ModuleScript.Name` as the id.

### `Ambience.push(id: string, options: { transition: number? }?)`

Activate a layer. Lighting properties are resolved by priority (highest wins
per-property). Sound tracks start playing and fade in over the transition duration.
No-op if the layer is already active.

### `Ambience.pop(id: string, options: { transition: number? }?)`

Deactivate a layer. Sound tracks fade out and stop. Lighting smoothly transitions
to the new resolved state. No-op if the layer is not active.

### `Ambience.set(id: string, options: { transition: number? }?)`

Pop all active layers and push the given one. Convenience for single-preset games.

### `Ambience.clear(options: { transition: number? }?)`

Pop all active layers.

### `Ambience.isActive(id: string): boolean`

Return whether a layer with the given id is currently active.

### `Ambience.getActive(): { string }`

Return a list of currently active layer ids (highest priority first).

### `Ambience.preset(p: Preset): Preset`

Identity function for editor autocomplete. Accepts and returns a `Preset` table
unchanged.

### `Ambience.Track`

The Track builder module. Used to create sound tracks for presets.

| Constructor | Description |
|---|---|
| `Track.new(pickFn)` | Low-level: function receives state table, returns a Sound or nil |
| `Track.looping(sound)` | Plays a single Sound on repeat |
| `Track.random(sounds)` | Picks a random Sound from the list each cycle |

| Builder method | Description |
|---|---|
| `:ModifyVolume(n \| fn)` | Multiply volume by a constant or per-frame function |
| `:AutoFadeInOut(seconds?)` | Fade in/out at start/end of each sound (default 1s) |
| `:OnlyPlayWhile(fn)` | Pause when callback returns false, resume when true |
| `:OnlyStartPlayingIf(fn)` | Skip starting a new sound when callback returns false |
| `:AddRandomDelay(min, max)` | Wait a random interval between min and max seconds between plays |

## How layering works

**Lighting**: Active layers are sorted by priority (highest first). A virtual
default layer with Roblox Studio defaults sits at the bottom of the stack and
cannot be removed. Resolution is two-pass per property:
- top-down to find the highest-priority fixed base value while collecting functions
- bottom-up to apply collected functions from low to high priority

The virtual default ensures that service properties (`Lighting`, `Workspace`)
always revert to Roblox defaults when no layer defines them, and modifier
functions always receive a real base value. Instance-based groups (Sky,
Atmosphere, Clouds, SunRaysEffect, ColorCorrectionEffect) are not part of the
default -- they are destroyed when no active layer defines them.

During transitions, only properties defined by the pushed/popped layer are
interpolated. All other properties (including dynamic values like a ticking
`ClockTime`) continue updating live.

**Sound**: All active layers' tracks play simultaneously. Each layer's tracks
share a transition volume that fades in on push and out on pop, independent of
other layers.

## License

MIT
