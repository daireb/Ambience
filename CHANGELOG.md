# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-16

### Fixed

- Instance-based lighting groups (Sky, Atmosphere, Clouds, SunRaysEffect,
  ColorCorrectionEffect) are now correctly destroyed when no active layer
  defines them. Previously, `clear_stale_instances` was a no-op due to
  `pairs()` skipping nil table entries.

### Changed

- A virtual default layer with Roblox Studio defaults is now always present
  at the bottom of the resolution stack. Service properties (`Lighting`,
  `Workspace`) always revert to Roblox defaults when no layer defines them.
  Modifier functions always receive a real base value instead of `nil`.

## [0.1.1] - 2026-03-06

### Fixed

- Lighting functions without a fixed base value (e.g. a standalone
  `ClockTime = function(_current) return os.clock() % 24 end`) are no longer
  silently skipped. Functions now receive `nil` when no lower-priority base
  exists, allowing dynamic absolute values to work as standalone layers.

## [0.1.0] - 2026-03-06

Initial release with layered push/pop architecture, modifier functions,
selective per-property transitions, and additive sound layering.
