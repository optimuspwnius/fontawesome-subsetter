require_relative "lib/fontawesome_subsetter/version"

Gem::Specification.new do | spec |
  spec.name          = "fontawesome_subsetter"
  spec.version       = FontawesomeSubsetter::VERSION
  spec.authors       = ["16554289+optimuspwnius@users.noreply.github.com"]
  spec.email         = ["16554289+optimuspwnius@users.noreply.github.com"]

  spec.summary       = "FontAwesome subsetter for Rails — tree-shakes unused icons from font files and CSS."
  spec.description   = "Scans your views and helpers for icon() calls, subsets FontAwesome WOFF2 fonts via pyftsubset, " \
                        "and generates minimal CSS. Includes a Puma plugin for development watch mode, a Rails view helper, " \
                        "and a rake task that hooks into assets:precompile."
  spec.homepage      = "https://github.com/optimuspwnius/fontawesome-subsetter"
  spec.license       = "MIT"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "LICENSE.txt",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "actionview", ">= 7.0"
  spec.add_dependency "sass-embedded", ">= 1.0"
  spec.add_dependency "listen", ">= 3.0"

  # Optional — only needed for development watch mode
  spec.add_development_dependency "puma", ">= 5.0"
end
