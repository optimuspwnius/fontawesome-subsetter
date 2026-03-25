# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Renamed Puma plugin from `fontawesome` to `fontawesome_subsetter` to match the gem name

### Fixed

- Removed stub `class FontawesomeSubsetter` from Puma plugin file that clashed with the gem's module definition

## [0.1.4] - 2026-03-24

### Added

- Custom Sass importer (`FontawesomeSassImporter`) that strips populated `$icons` and `$brand-icons` maps from FontAwesome's `variables.scss` in memory at compile time

## [0.1.3] - 2026-03-24

### Changed

- Lazily require `sass-embedded` in `subset_stylesheets` to avoid loading it in production

## [0.1.2] - 2026-03-24

### Fixed

- Moved `listen` from development dependency to runtime dependency — required by the Puma watch plugin

## [0.1.1] - 2026-03-24

### Added

- Published to RubyGems

## [0.1.0] - 2026-03-24

### Added

- Initial release
- `icon` view helper for rendering FontAwesome icons in Rails views
- Subsetter that scans views/helpers for `icon()` calls and subsets WOFF2 fonts via `pyftsubset`
- Dynamic SCSS compilation with only used icons
- Puma plugin for development watch mode (auto-rebuild on file changes)
- Rake task `fontawesome:subset` that hooks into `assets:precompile`
- Configurable scan globs, icon regex, paths, and SCSS template
