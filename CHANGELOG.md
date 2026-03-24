# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
