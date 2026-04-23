# FontAwesome Subsetter

A Rails gem that tree-shakes FontAwesome 7 — scans your views and helpers for `icon()` calls, subsets WOFF2 font files to include only used glyphs, and generates minimal CSS.

## Requirements

- **FontAwesome** files in `vendor/fontawesome/` (metadata, scss, webfonts)
- **pyftsubset** (from [fonttools](https://github.com/fonttools/fonttools)): `pip install fonttools brotli`
- **sass-embedded** gem for SCSS compilation

## Installation

Add to your Gemfile:

```ruby
gem "fontawesome_subsetter"
```

Then run `bundle install`.

## Setup

### Directory Structure

The gem expects FontAwesome files in your project at:

```
vendor/
  fontawesome/
    metadata/
      icons.yml
    scss/
      variables.scss
      functions.scss
      mixins.scss
      core.scss
      animated.scss
      icons.scss
      solid.scss
      regular.scss
      ...
    webfonts/
      fa-solid-900.woff2
      fa-regular-400.woff2
      fa-brands-400.woff2
      fa-duotone-900.woff2
      fa-thin-100.woff2
```

## Features

### 1. Icon Helper

The gem provides an `icon` helper available in all views:

```slim
= icon(:fas, :download, "Download", class: "mr-1")
= icon(:far, :check)
= icon(:fab, :github)
```

### 2. Puma Plugin (Development Watch Mode)

Add to your `config/puma.rb`:

```ruby
if ENV.fetch("RAILS_ENV", "development") == "development"
  plugin :fontawesome_subsetter
end
```

This watches `app/views/`, `app/helpers/`, and `app/components/` for changes and automatically rebuilds subsetted fonts.

### 3. Rake Task (Deploy)

The gem automatically hooks into `assets:precompile`:

```bash
rake assets:precompile  # fontawesome:subset runs first
```

You can also run it manually:

```bash
rake fontawesome:subset
```

## Configuration

```ruby
# config/initializers/fontawesome_subsetter.rb
FontawesomeSubsetter.configure do | config |
  # Paths to scan for icon() calls (defaults shown)
  config.scan_globs = ["app/views/**/*.slim", "app/helpers/**/*.rb"]

  # Regex to match icon() calls (default shown)
  config.icon_regex = /icon\(\s*:(?<prefix>fas|far|fab|fad|fal|fat)\s*,\s*:(?<icon>[\w_\-]+)\b/

  # Override default paths (optional — defaults use Rails.root)
  # config.meta_path = Rails.root.join("vendor", "fontawesome", "metadata", "icons.yml")
  # config.fonts_dir = Rails.root.join("vendor", "fontawesome", "webfonts")
  # config.build_dir = Rails.root.join("app", "assets", "builds")

  # Custom SCSS template (optional — receives @styles hash, must return SCSS string)
  # config.scss_template = ->(styles) { "..." }

  # Additional SCSS variables to inject into the `@use "variables" with (...)` block.
  # Keys may be symbols/strings (with or without leading `$`). Values are raw SCSS.
  # config.variables = {
  #   "fa-font-display" => "swap",
  #   "fa-css-prefix"   => '"fa"'
  # }

  # Optional presentational FontAwesome SCSS partials to include. Defaults to `:all`.
  # Available: "sizing", "widths", "list", "bordered", "animated", "rotated-flipped", "stacked"
  # (Core partials — functions, mixins, core, icons — are always included.)
  # config.features = ["animated"]
end
```

## Deploying with Kamal (Docker)

`pyftsubset` must be available during `assets:precompile` in your Docker build stage. Add the following to the **build** stage of your Dockerfile:

```dockerfile
# In the build stage, install pyftsubset for font subsetting
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y python3 python3-pip python3-venv pipx && \
    pipx ensurepath && \
    pipx install fonttools && \
    pipx inject fonttools brotli && \
    ln -s /root/.local/bin/pyftsubset /usr/local/bin/pyftsubset && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
```

Font subsetting runs automatically during `assets:precompile`, so no additional Dockerfile steps are needed — just make sure the line above appears before your `RUN ... assets:precompile` step.

The final (runtime) stage does **not** need `pyftsubset`; subsetted fonts are already baked into the image.

## License

[MIT](LICENSE.txt) — Copyright (c) 2026
