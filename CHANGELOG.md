# Changelog

All notable changes to UltraCursorFX will be documented in this file.

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
- **Comprehensive test suite**: 167 automated tests (up from 63)
- **98.8% code coverage** on core addon modules
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
