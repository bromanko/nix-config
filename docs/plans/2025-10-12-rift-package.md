# Rift Package Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Create a Nix package for Rift window manager with home-manager module for declarative configuration and service management.

**Architecture:** Rust package built from GitHub main branch, home-manager module that installs the package, creates launchd agent for auto-start, and symlinks config file from repo using out-of-store path (editable in place).

**Tech Stack:** Nix, rustPlatform, home-manager, launchd, jujutsu

---

## Task 1: Create Rift Package Skeleton

**Files:**
- Create: `packages/rift.nix`

**Step 1: Create package file with placeholder hashes**

Create `packages/rift.nix`:

```nix
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "main";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  buildInputs = [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.ApplicationServices
  ];

  # Disable tests - may require GUI/accessibility
  doCheck = false;

  meta = {
    description = "Tiling window manager for macOS";
    homepage = "https://github.com/acsandmann/rift";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "rift";
  };
}
```

**Step 2: Verify file syntax**

Run: `nix-instantiate --parse packages/rift.nix`
Expected: No syntax errors

**Step 3: Commit**

```bash
jj commit -m "feat: add rift package skeleton with placeholder hashes"
```

---

## Task 2: Get Correct Source Hash

**Files:**
- Modify: `packages/rift.nix`

**Step 1: Attempt build to get source hash**

Run: `nix build .#rift 2>&1 | tee /tmp/rift-build.log`
Expected: Build fails with error showing correct hash for src

**Step 2: Extract correct hash from error message**

The error will show something like:
```
specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
got:      sha256-[ACTUAL-HASH-HERE]
```

Copy the "got" hash value.

**Step 3: Update source hash in package**

In `packages/rift.nix`, replace:
```nix
    hash = lib.fakeHash;
```

With:
```nix
    hash = "sha256-[ACTUAL-HASH]";
```

**Step 4: Verify syntax**

Run: `nix-instantiate --parse packages/rift.nix`
Expected: No syntax errors

**Step 5: Commit**

```bash
jj commit -m "fix: update rift source hash"
```

---

## Task 3: Get Correct Cargo Hash

**Files:**
- Modify: `packages/rift.nix`

**Step 1: Attempt build to get cargo hash**

Run: `nix build .#rift 2>&1 | tee /tmp/rift-build2.log`
Expected: Build fails with error showing correct cargoHash

**Step 2: Extract correct cargo hash from error message**

The error will show something like:
```
specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
got:      sha256-[ACTUAL-CARGO-HASH]
```

Copy the "got" hash value.

**Step 3: Update cargo hash in package**

In `packages/rift.nix`, replace:
```nix
  cargoHash = lib.fakeHash;
```

With:
```nix
  cargoHash = "sha256-[ACTUAL-CARGO-HASH]";
```

**Step 4: Verify syntax**

Run: `nix-instantiate --parse packages/rift.nix`
Expected: No syntax errors

**Step 5: Commit**

```bash
jj commit -m "fix: update rift cargo hash"
```

---

## Task 4: Complete Package Build

**Files:**
- Modify: `packages/rift.nix` (if additional frameworks needed)

**Step 1: Build package**

Run: `nix build .#rift -L`
Expected: Build succeeds, or fails with missing framework errors

**Step 2: If build fails with missing frameworks**

Check error for missing frameworks (e.g., "framework 'Foundation' not found").

Add missing frameworks to `buildInputs`:
```nix
  buildInputs = [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.ApplicationServices
    darwin.apple_sdk.frameworks.Foundation  # example
    # Add others as needed
  ];
```

Repeat build until successful.

**Step 3: Verify binaries exist**

Run: `ls -la result/bin/`
Expected: See `rift` and `rift-cli` binaries

**Step 4: Test binary execution**

Run: `./result/bin/rift --help`
Expected: Shows help message without errors

**Step 5: Commit if changes were made**

```bash
jj commit -m "fix: add missing frameworks to rift build"
```

---

## Task 5: Create Config Directory and File

**Files:**
- Create: `configs/rift/config.toml`

**Step 1: Create config directory**

Run: `mkdir -p configs/rift`
Expected: Directory created

**Step 2: Download default config**

Run: `curl -o configs/rift/config.toml https://raw.githubusercontent.com/acsandmann/rift/main/rift.default.toml`
Expected: File downloaded successfully

**Step 3: Verify file contents**

Run: `head -20 configs/rift/config.toml`
Expected: See TOML configuration content

**Step 4: Commit**

```bash
jj commit -m "feat: add default rift configuration"
```

---

## Task 6: Create Home Manager Module

**Files:**
- Create: `modules/home-manager/desktop/apps/rift.nix`

**Step 1: Create module file**

Create `modules/home-manager/desktop/apps/rift.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.rift;
in
{
  options.modules.desktop.apps.rift = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = [ pkgs.my.rift ];

      # Symlink config from repo (out-of-store path)
      xdg.configFile."rift/config.toml".source =
        config.hm.lib.file.mkNixConfigSymlink "/configs/rift/config.toml";

      # Launchd agent for auto-start
      launchd.agents.rift = {
        enable = true;
        config = {
          ProgramArguments = [ "${pkgs.my.rift}/bin/rift" ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          StandardOutPath = "${config.hm.home.homeDirectory}/Library/Logs/rift.log";
          StandardErrorPath = "${config.hm.home.homeDirectory}/Library/Logs/rift.log";
        };
      };
    };
  };
}
```

**Step 2: Verify syntax**

Run: `nix-instantiate --parse modules/home-manager/desktop/apps/rift.nix`
Expected: No syntax errors

**Step 3: Commit**

```bash
jj commit -m "feat: add rift home-manager module with launchd service"
```

---

## Task 7: Format All Nix Files

**Files:**
- Modify: `packages/rift.nix`, `modules/home-manager/desktop/apps/rift.nix`

**Step 1: Format package file**

Run: `nixfmt packages/rift.nix`
Expected: File formatted

**Step 2: Format module file**

Run: `nixfmt modules/home-manager/desktop/apps/rift.nix`
Expected: File formatted

**Step 3: Format config file if created**

Run: `nixfmt configs/rift/config.toml` (only if it's .nix)
Expected: Skip - it's a .toml file, not Nix

**Step 4: Check for changes**

Run: `jj diff`
Expected: See formatting changes if any

**Step 5: Commit if changes exist**

```bash
jj commit -m "style: format rift nix files"
```

---

## Task 8: Test Integration (Manual)

**Files:**
- N/A (testing only)

**Step 1: Document test steps**

Add comment to plan about manual testing:

1. Enable module in a Darwin host config:
   ```nix
   modules.desktop.apps.rift.enable = true;
   ```

2. Rebuild system:
   ```bash
   darwin-rebuild switch --flake .
   ```

3. Check launchd service status:
   ```bash
   launchctl list | grep rift
   ```

4. Check log file:
   ```bash
   tail -f ~/Library/Logs/rift.log
   ```

5. Test activation hotkey: Alt + Z

6. Verify config symlink:
   ```bash
   ls -la ~/.config/rift/config.toml
   ```

7. Test config hot-reload by editing `configs/rift/config.toml`

**Step 2: Note testing status**

This task is informational only - actual testing happens after implementation.

---

## Task 9: Create Summary Documentation

**Files:**
- Create: `docs/rift-setup.md` (optional, only if needed)

**Step 1: Decide if documentation needed**

Ask: Does this need separate documentation, or is the module self-documenting?

Decision: Skip separate documentation - module is self-documenting and follows existing patterns.

**Step 2: Skip this task**

No action needed.

---

## Implementation Notes

**Verification Commands:**
- Build package: `nix build .#rift -L`
- Check syntax: `nix-instantiate --parse <file>`
- Format: `nixfmt <file>`
- Test flake: `nix flake check`
- View logs: `tail -f ~/Library/Logs/rift.log`

**Expected Issues:**
1. Missing macOS frameworks during build - add to buildInputs
2. Tests requiring GUI access - disabled with doCheck = false
3. Accessibility permissions needed - user must grant manually

**Success Criteria:**
- Package builds successfully
- Both binaries (rift, rift-cli) present in result
- Module enables and configures service
- Config symlink points to repo file (editable in place)
- Launchd service starts on login
