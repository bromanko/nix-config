# Nix System Configuration Guide

## Commands
- Format: `nixfmt path/to/file.nix`
- Check syntax: `nix-instantiate --parse path/to/file.nix`
- Build darwin system: `nix build .#darwinConfigurations.hostname.system`
- Test config: `nix flake check`

## Coding Style
- Use 2-space indentation for Nix files
- Follow RFC-style formatting (enforced by nixfmt-rfc-style)
- Group imports at the top of files
- Use camelCase for variables and functions
- Use descriptive names for modules and options
- Organize options with consistent structure (enable, config, package)
- Comment complex expressions or non-obvious configurations
- Prefer attribute sets for configuration options
- Use age for secret management
- Follow existing patterns for adding new modules/hosts
