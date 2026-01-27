# Changelog

All notable changes to UltraCursorFX will be documented in this file.

## [0.7.0] - 2025-01-27

### Added
- **Screen Edge Warning System** Visual alerts when cursor approaches screen boundaries
  - **Animated Warning Arrows** - Appear at top/bottom/left/right edges when cursor gets close
  - **Pulsing Animation** - Smooth sin-wave pulse to grab attention without being jarring
  - **Smart Detection** - Shows multiple arrows simultaneously when near corners
  - **Full Customization**:
    - Trigger Distance slider (20-150 pixels) - How close to edge before warning appears
    - Arrow Size slider (32-128 pixels) - Scale warning arrows to your preference
    - Opacity control (30-100%) - Adjust visibility to match your setup
    - Master toggle - Enable/disable entire system
  - **Profile-Specific Defaults**:
    - World: 50px distance, medium sensitivity
    - Raid: 40px distance, larger arrows (70px), more visible (90% opacity) for intense gameplay
    - Dungeon: Balanced 50px distance
    - Arena: Aggressive 30px distance, largest arrows (80px), fully visible for competitive edge
    - Battleground: Balanced settings
  - **Slash Command**: `/ucfx edge` to toggle edge warnings on/off
  - **Perfect for**: Large monitor users, ultrawide displays, accessibility needs, VR players

### Technical
- New functions: `BuildEdgeWarnings()`, `UpdateEdgeWarnings()`
- Warnings positioned dynamically based on cursor and screen dimensions
- Uses `UIParent:GetWidth()` and `UIParent:GetHeight()` for accurate screen edge detection
- Arrows rotated appropriately (up/down/left/right) using `SetRotation()`
- Independent pulse timers for each edge prevent synchronization
- 4 new settings: `edgeWarningEnabled`, `edgeWarningDistance`, `edgeWarningSize`, `edgeWarningOpacity`
- Integrated into main `OnUpdate()` loop for real-time responsiveness

### Testing & Quality
- **30 new comprehensive tests** for edge warning system
- Test count increased from **227 to 257 tests** (+13%)
- Full coverage of:
  - Edge detection logic (all 4 edges + corners)
  - Arrow positioning and rotation
  - Pulse animation timing
  - Distance threshold behavior
  - Profile-specific settings
  - Integration with BuildTrail
  - Edge cases (0,0 coordinates, max coordinates, threshold boundaries)
- Enhanced WoW API mocks with `UIParent:GetWidth()` and `GetHeight()`
- **All 257 tests passing**

### UI/UX
- New "Screen Edge Warnings" section in settings panel
- 3 sliders + 1 checkbox for complete control
- Helpful descriptions explain each setting
- Auto-save to current profile on changes
- Visual feedback in UI shows current values

## [0.6.3] - 2026-01-26

### Fixed
- **Tooltip secret value comparison error** - Wrapped `GameTooltip:GetUnit()` in pcall to safely handle tainted/secret values when mousing over auras or protected game elements
  - Prevents "attempt to compare a secret value" errors in reticle mouseover detection
  - Maintains interactive object detection functionality for normal cases

## [0.6.2] - 2025-01-26

### Quality & Testing
- **Comprehensive Test Suite Expansion** 🧪
  - Added **60 new tests** for smart reticle system, fade effects, and memory management
  - Test count increased from **167 to 227 tests** (+36%)
  - **Effects.lua coverage improved from 67.89% to 97.37%** (+29.48%)
  - Overall core addon coverage: **97.4%** (excluding UI callbacks)
  - All reticle rendering functions now fully tested (6 styles)
  - Complete coverage of BuildReticle, UpdateReticle, and all rendering variants
  - Fade system, combat opacity boost, and color detection fully tested
  - **30 new cleanup/memory leak prevention tests** proving proper resource management

### Testing Infrastructure
- Enhanced WoW API mocks to track texture properties (color, alpha, size, rotation)
- Improved test reliability and debugging capabilities
- Zero test failures across entire suite
- **Memory Management Verification**:
  - Texture cleanup on rebuild (no orphaned textures)
  - Click particle pool enforcement (200 particle limit)
  - Proper cleanup during combat state transitions
  - Profile switching without accumulation
  - Table memory management (wipe without references)
  - Edge case handling (zero points, rapid toggles)

### Maintainability
- Demonstrates ongoing commitment to code quality
- Robust test coverage ensures stability for future updates
- Better documentation through comprehensive test cases

### Developer Notes
This release focuses entirely on internal quality improvements. No user-facing changes—the addon works exactly the same, but is now significantly better tested and more maintainable for future development.

## [0.6.1]

### Fixed
- **Luacheck linter warnings** - Added missing WoW API globals to .luacheckrc
  - Added Unit API functions: `UnitExists`, `UnitCanAttack`, `UnitIsFriend`, `UnitIsDead`, `UnitIsUnit`, `GetTime`
  - Added UIDropDownMenu API functions: `UIDropDownMenu_SetWidth`, `UIDropDownMenu_Initialize`, `UIDropDownMenu_CreateInfo`, `UIDropDownMenu_AddButton`, `UIDropDownMenu_SetText`
  - Resolved all 12 linter warnings (6 in Effects.lua, 6 in UI.lua)
  - Clean build: 0 warnings / 0 errors in 9 files

### Quality
- All 227 tests still passing
- Zero linter warnings achieved
- Code quality maintained

## [0.6.0]

### Added
- **Smart Reticle System** 🎯 - Dynamic crosshair that changes color and appearance based on mouseover targets
  - **Target-Aware Color System**:
    - **Red reticle** for attackable enemies (with 2x faster rotation animation)
    - **Green reticle** for friendly players (with smooth pulse animation)
    - **Gold reticle** for interactive objects and NPCs
    - **Custom color** matches your trail when hovering nothing (60% opacity to reduce clutter)
  - **6 Authentic Reticle Styles**:
    - **Crosshair** - Classic FPS + shape with center dot (default for World profile)
    - **Circle Dot** - Red dot sight style with circle ring and bright center (default for Dungeon)
    - **T-Shape** - Rangefinder/sniper scope aesthetic with tick marks (default for Arena)
    - **Military** - Corner brackets with rotating segments (default for Raid/Battleground)
    - **Cyberpunk** - 8-segment neon ring with alternating lengths
    - **Minimal** - Simple corner L-brackets with minimal visual noise
  - **Full Customization Controls**:
    - Reticle size slider (40-150 pixels)
    - Brightness multiplier (0.5x - 2.0x)
    - Opacity control (20-100%)
    - Rotation speed (0x - 3.0x for applicable styles)
    - Style dropdown with live preview
  - **Profile Integration** - Each situational profile has optimized reticle defaults
  - **Slash Command**: `/ucfx reticle` to toggle reticle system on/off
  - **Performance**: Minimal overhead, runs once per frame with simple conditionals
  - **Accessibility**: Enhances target acquisition for players with vision challenges

### Changed
- Extended all profile defaults to include reticle settings
  - World: Crosshair (size 80, classic feel)
  - Raid: Military (size 90, brighter 1.2x, faster rotation 1.5x)
  - Dungeon: Circle Dot (size 75, slower rotation 0.8x)
  - Arena: T-Shape (size 100, brightest 1.3x, fastest rotation 2.0x for competitive edge)
  - Battleground: Military (size 85, balanced settings)
- Updated `BuildTrail()` to also build reticle segments
- Enhanced UI with new "Smart Reticle System" section containing 6 controls + dropdown
- Updated documentation with reticle feature showcase

### Technical
- New reticle rendering functions: `BuildReticle()`, `UpdateReticle()`, `RenderCrosshairReticle()`, `RenderCircleDotReticle()`, `RenderTShapeReticle()`, `RenderMilitaryReticle()`, `RenderCyberpunkReticle()`, `RenderMinimalReticle()`
- Mouseover detection using WoW Unit API: `UnitExists()`, `UnitCanAttack()`, `UnitIsFriend()`, `UnitIsDead()`, `UnitIsUnit()`
- Interactive object detection using `GameTooltip:IsShown()` and `GameTooltip:GetUnit()`
- Reticle segments stored in `addon.reticleSegments` array
- Rotation state tracked in `addon.reticleRotation` variable
- Uses `SetRotation()` API for smooth segment animations
- 6 new default settings: `reticleEnabled`, `reticleStyle`, `reticleSize`, `reticleBrightness`, `reticleOpacity`, `reticleRotationSpeed`

### Testing & Quality
- **All 227 tests passing** - Complete backwards compatibility
- **Zero linter warnings** - Clean code style maintained
- **New WoW API mocks**: Added `UnitExists`, `UnitCanAttack`, `UnitIsFriend`, `UnitIsDead`, `UnitIsUnit`, `GetTime`, `UIDropDownMenu` functions
- **Enhanced test mocks**: Added `SetRotation()`, `SetWidth()`, `SetJustifyH()` support for UI elements
- **~250 lines of new code** across Core.lua, Effects.lua, UI.lua, Commands.lua

### Documentation
- Created RETICLE_STYLES.md with ASCII art guide for all 6 styles
- Updated README.md with Smart Reticle feature highlight
- Updated DESCRIPTION.md with comprehensive reticle documentation
- Created RETICLE_FEATURE.md with technical implementation details

## [0.5.0]

### Added
- **Opacity & Fade Control** - Fine-tune trail visibility with new opacity and fade options
  - **Global Opacity Slider** - Control overall trail visibility from 10% to 100%
  - **Fade Mode Toggle** - Enable smooth gradual fading from head to tail for ethereal effects
  - **Fade Strength Slider** - Adjust how aggressively particles fade along the trail (0-100%)
  - **Combat Opacity Boost** - Automatically increase trail visibility by 30% during combat
  - `/ucfx fade` command to toggle fade mode
  - `/ucfx boost` command to toggle combat opacity boost
  - UI controls in new "Opacity & Fade" section
  - Works seamlessly with all existing features (rainbow, comet, profiles)
  - Profile-aware settings for different situations

### Changed
- Extended all profile defaults to include opacity and fade settings
  - Raid profile: Pre-configured with fade enabled and combat boost
  - Arena profile: Aggressive fade for competitive visibility
  - Other profiles optimized for their respective scenarios

### Benefits
- **Enhanced Accessibility**: Fine-tune visibility for specific vision needs
- **Performance**: Reduce visual clutter with lower opacity while maintaining functionality
- **Visual Customization**: Create beautiful ethereal effects with fade mode
- **Combat Utility**: Never lose cursor during intense fights with automatic opacity boost

## [0.4.0]

### Added
- **Combat Only Mode** - New toggle to only show cursor trail during combat
  - Perfect for reducing visual clutter outside of combat
  - `/ucfx combat` command to toggle
  - UI checkbox in Basic Settings
  - Automatically enables/disables trail when entering/leaving combat
  - Works seamlessly with all other features and profiles

### Changed
- Refactored cursor state management with new `UpdateCursorState()` function
  - Centralized logic for enabling/disabling cursor trail
  - Improved handling of combat state transitions
  - Better integration with existing features (profiles, commands)

### Fixed
- Proper cleanup of trail particles when disabling addon or exiting combat
  - All particles are now properly hidden when trail is disabled
  - Prevents orphaned particles from remaining visible

## [0.3.1]

### Fixed
- **CRITICAL: Memory leak in click effects** - Particles now use object pooling
  - Previously, every click created new textures that were never properly released
  - This caused memory to grow over time, leading to crashes or disconnects after extended play
  - Now uses a particle pool (max 200 textures) for better performance and stability
  - Should eliminate random crashes and logout issues

## [0.3.0]

### Added
- **Combat Only Mode** - New toggle to only show cursor trail during combat
  - Perfect for reducing visual clutter outside of combat
  - `/ucfx combat` command to toggle
  - UI checkbox in Basic Settings
  - Automatically enables/disables trail when entering/leaving combat
  - Works seamlessly with all other features and profiles
- **Release automation script** (`release.sh`) for managing versions and tags
  - Supports major/minor/patch version increments
  - Supports alpha/beta/custom pre-releases
  - Automatic version updates in README.md
  - Enforces CHANGELOG.md updates before release
  - CurseForge-compatible tag formats
  - Interactive prompts with confirmation
- **Comprehensive release documentation** (RELEASE.md)
  - Complete guide for creating releases
  - CurseForge webhook integration details
  - Version format specifications
  - Troubleshooting guide

### Changed
- **UI improvements**:
  - Moved Import/Export settings to the top of settings panel for better accessibility
  - Improved settings UI spacing and alignment for better readability
- **Rainbow mode display**: Shows "R" indicator instead of the current color when rainbow mode is active
- **GitHub Actions workflow**: Updated to support webhook-based CurseForge deployment instead of manual API upload

### Fixed
- **Profile UI bugs**:
  - Profile UI now correctly loads settings after auto-saving
  - Profile UI properly auto-reloads when loading profiles
  - Fixed issue where profile settings weren't immediately visible after save

### Development
- Added automated release workflow with quality gates
- Release package now excludes development files (test specs, old files)
- Enhanced CI/CD pipeline for stable releases

## [0.2.0] - 2026-01-22

### Added - Situational Profiles System 🎯
- **Automatic profile switching** based on current location/instance type
- **5 pre-configured profiles**: World, Raid, Dungeon, Arena, Battleground
- **Profile management UI** in settings panel with Save/Load buttons
- **Profile persistence** - each profile stores complete cursor configuration
- **Zone detection** using WoW API (IsInInstance, GetInstanceInfo)
- **Auto-switching** on PLAYER_ENTERING_WORLD event
- **Automatic migration** - existing user settings are preserved and migrated to World profile
- **Profile commands**:
  - `/ucfx profiles` - Toggle automatic profile switching
  - `/ucfx save <profile>` - Save current settings to a profile
  - `/ucfx load <profile>` - Load settings from a profile
- **Default profiles** with optimized settings for each situation:
  - Raid: Red comet with enhanced click effects
  - Dungeon: Purple balanced trail
  - Arena: Orange fast-response spark
  - Battleground: Gold competitive setup
  - World: Cyan default comfortable settings
- **Profile status display** showing current active profile
- **Notification system** alerts when profiles auto-switch

### Changed
- Extended saved variables to include profiles table structure
- Added forward declarations for profile functions
- Enhanced documentation with situational profile examples
- Updated README with comprehensive profile usage guide

### Fixed
- **Backward compatibility**: Existing user settings are automatically migrated to World profile on first load
- Users upgrading from older versions won't lose their customizations
- Migration only runs once per SavedVariables file

### Testing & Quality
- **Comprehensive test suite**: 227 automated tests (up from 63)
- **97.4% code coverage** on core addon modules
- **Docker-based testing environment** for reproducible test runs
- **GitHub Actions CI/CD** - tests run on every push and PR
- **Quality gates**: Tags and releases blocked if tests fail
- **LuaCheck linting**: Zero warnings with proper WoW API globals configured
- **New test files**: commands_spec, effects_spec, init_spec, ui_spec
- **Mouse click simulation** for testing click effects
- **Full color wheel coverage** testing all HSV segments

### Technical
- Profile data structure stored in `UltraCursorFXDB.profiles`
- Profile functions: `GetCurrentZoneProfile()`, `SaveToProfile()`, `LoadFromProfile()`, `SwitchToZoneProfile()`
- Event handler for `PLAYER_ENTERING_WORLD` to trigger profile switching
- Situational enable/disable flag: `UltraCursorFXDB.situationalEnabled`
- Migration flag: `UltraCursorFXDB.profilesMigrated` ensures one-time migration
- Smart migration detects if user has customized settings vs defaults before migrating
- Coverage badge: Excludes UI callbacks, focuses on core business logic

## [0.1.0] - 2026-01-22

### Added
- Initial release of UltraCursorFX
- Customizable cursor trail effects with smooth animations
- Rainbow mode with adjustable speed
- Click effects with particle bursts
- Multiple particle shapes: Star, Skull, Spark, Circle
- Comet mode for elongated trailing effects
- Full color customization with preset colors
- Import/Export settings functionality
- Keybinding support for quick toggle
- HDR pulse flash effect
- Comprehensive settings panel with icon
- All settings persist across sessions

### Features
- Adjustable trail points (10-100)
- Customizable particle size and glow
- Trail smoothness control
- Pulse speed adjustment
- Click particle customization
- Full WoW 12.0+ compatibility
