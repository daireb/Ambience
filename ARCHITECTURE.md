# Architecture

## File structure

```
src/
  init.luau       Orchestrator: public API, layer state, transition scheduling
  Lighting.luau   Lighting utilities: resolve, lerp, write to Roblox instances
  Track.luau      Sound track builder class with per-frame volume/playback control
```

## Core concepts

### Presets

A preset is a plain table with optional `priority`, `lighting`, and `sounds`
fields. Presets are registered by id and stored in a flat registry. They are
never mutated after registration.

### Layers

The active layer stack is a sorted list of `LayerState` entries (highest
priority first). Each entry references its preset and holds a fade token for
sound transition cancellation. Layers are added via `push` and removed via
`pop`. `set` is shorthand for "pop everything else, push this one."

### Lighting resolution

Resolution is two-pass per property across the active layer stack:

```
Pass 1 (top-down):   collect modifier functions, stop at first fixed value
Pass 2 (bottom-up):  apply collected functions to the base value
```

```
Layer stack (highest priority first):

  Storm  [pri 20]  Brightness = fn(c) -> c * 0.8    <- collected as modifier
  Rain   [pri 10]  Brightness = fn(c) -> c * 0.5    <- collected as modifier
  Day    [pri  0]  Brightness = 3                    <- base found, stop

Result: 3 -> * 0.5 -> * 0.8 = 1.2
```

Fixed values override. Functions receive the current built-up value and
transform it. If no fixed base exists for a property, all functions for
it are skipped.

Any property backed by a function anywhere in the stack is flagged as
dynamic. When dynamic properties exist, a per-frame loop re-resolves
and writes them after the transition completes.

### Lighting transitions

When `push` or `pop` is called with a transition duration:

1. `current_lighting_state` is frozen as the from-snapshot.
2. The preset's lighting keys are extracted (`get_lighting_keys`).
3. A transition loop runs for the specified duration. Each frame:
   - The full layer stack is re-resolved to get the live target.
   - Properties **defined by the pushed/popped preset** are lerped from the
     frozen snapshot toward the live target by the transition alpha.
   - All other properties are written directly from the live target.
4. After the transition, a final snapshot is written. If dynamic values
   remain, the dynamic loop continues.

This selective lerping ensures that unrelated dynamic properties (like a
ticking `ClockTime` from a lower layer) are never interpolated or delayed
by an unrelated layer change.

Rapid successive transitions are handled naturally: each new call freezes
whatever `current_lighting_state` is at that instant (mid-interpolation or
otherwise) as the new from-snapshot. The previous transition loop is
cancelled via the `lighting_transition_token` mechanism.

### Sound management

Sounds are additive across layers. Each layer's tracks play independently.

On push:
- All tracks in the preset's `sounds` list are activated.
- `_transitionVolume` starts at 0 and fades to 1 over the transition duration.

On pop:
- `_transitionVolume` fades from 1 to 0 over the transition duration.
- Tracks are stopped after the fade completes.

Each layer has a `fadeToken` that increments on each new fade operation,
cancelling any in-progress fade for that layer.

Track volume each frame is: `baseVolume * computeVolume(sound) * transitionVolume`

- `baseVolume`: the Sound instance's original Volume property
- `computeVolume`: stacked modifiers from the builder chain (`:ModifyVolume`, etc.)
- `transitionVolume`: controlled by the layer's fade system

### Cancellation tokens

Two token patterns prevent stale coroutines from writing:

- **`lighting_transition_token`**: incremented on every `refresh_lighting` call.
  Both the transition loop and the post-transition dynamic loop check this
  token each frame and exit if it no longer matches.

- **`fadeToken`** (per layer): incremented on each new sound fade operation.
  The fade coroutine exits if its token no longer matches, preventing
  overlapping fades on the same layer.

## Data flow

```
register(id, preset)
    -> presets[id] = preset

push(id, { transition = N })
    -> add_layer: insert into active_layers, sort by priority, activate tracks
    -> refresh_lighting(N, preset_keys):
        -> resolve_lighting(layers)        [Lighting.luau]
        -> selective_lerp_lightingdata     [Lighting.luau, per frame during transition]
        -> write_lightingdata              [Lighting.luau, writes to Roblox instances]
        -> start_dynamic_loop (if needed)

pop(id, { transition = N })
    -> remove_layer_at: remove from active_layers, fade out + stop tracks
    -> refresh_lighting(N, preset_keys):
        -> (same resolution/transition flow as push)
```

## Type design

Public types are exported from `init.luau`:
- `Preset`: what users define (priority, lighting, sounds)
- `Track`: the public track interface (builder methods + activate/stop)

Internal types are module-local:
- `TrackPrivate` (Track.luau): extends Track with `_currentSound`,
  `_playingId`, `_transitionVolume`, etc.
- `LayerState` (init.luau): id + preset + fadeToken
- `ResolvableLightingData` (Lighting.luau): lighting table where values
  can be either concrete or functions
- `LightingData` (Lighting.luau): lighting table with concrete values only
  (the resolved output)
