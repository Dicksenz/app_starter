## [1.1.5] - .cursor Folder Support

- Add support for copying the `.cursor` folder from templates to the new project

## [1.1.4] - FVM-Only Environment Support

- Add support for environments where global `flutter` and `dart` are missing
- Automatically switch to FVM mode if `fvm` is available but global `flutter` is not
- Update documentation for FVM-only activation and usage

## [1.1.3] - Robust FVM Integration

- Improve FVM version detection: searches parent directories for `.fvmrc` and falls back to `fvm flutter --version`
- Ensure exact FVM version is logged and propagated to the new project
- Add debug logging for FVM versioning status

## [1.1.2] - FVM Interaction & Detection Fixes

- Fix "freezing" when FVM requires user interaction (e.g., confirmation to install version)
- Improve automatic FVM version detection from `.fvmrc`
- Switch to interactive process execution for `flutter` and `fvm` commands

## [1.1.1] - FVM Refinements

- Add automatic FVM version detection from current directory (`.fvmrc`)
- Ensure `.fvmrc` is always created/updated in the new project when FVM is enabled
- Improve fallback logic for FVM versioning

## [1.1.0] - FVM Support

- Add support for FVM (Flutter Version Management)
- Add `--fvm` (or `-f`) flag to use `fvm flutter` instead of global `flutter`
- Add `--fvm-version` option to specify a specific Flutter version
- FVM preferences are now storable and displayable in config

## [1.0.0+3] - Internal updates

- Internal performance and reliability fixes

## [0.0.1] - Initial version

First release !

## [0.0.2] - Documentation fixes version

Just some documentation fixes

## [0.0.3] - Fix dependencies versions

Lower dependencies versions needed and remove flutter sdk dependency

## [0.0.4] - Fix dart executable

Add missing executable and fix some Readme issues

## [1.0.0] - First usable version

- Add storable configuration values
- Add configuration displaying command
- Add help displaying command
- Add better documentation in Readme

## [1.0.0+1] - Readme update

- Just fix Readme table format

## [1.0.0+2] - Readme update

- Trying to fix pub.dev markdown table format
