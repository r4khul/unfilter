# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-01-29

### Added

- **Advanced Search**: Users can now filter apps by Tech Stack (Flutter, React Native, Kotlin, etc.), App Name, and Package Name.
- **Battery Impact Analysis**: New modal in Task Manager to view detailed battery impact of running processes.
- **Privacy Policy**: Added support for viewing the app's privacy policy directly within the app.
- **Issue Templates**: specific templates for Bug Reports and Feature Requests to streamline contributions.
- **License**: Added MIT License to the project.

### Changed

- **UI/UX Consistency**: Refined all bottom sheets to have sharp, non-rounded corners for a unified design language.
- **System Overlay**: improved system bar integration for a seamless look in both Light and Dark modes.
- **Documentation**: Enhanced README with build badges and clearer gallery layouts.

## [1.0.0+2] - 2026-01-05

### Added

- **OTA Update System**: Rolled out a robust Over-The-Air update mechanism to deliver future updates directly to users.
- **Critical Fix**: Enforced `extractNativeLibs="true"` in Android Manifest to resolve `libflutter.so` loading crashes on POCO and MIUI devices.

## [1.0.0+1] - 2026-01-05

### Initial Release

- Initial public beta release of Unfilter.
- Core functionality: Tech stack detection, storage analysis, and task manager.
