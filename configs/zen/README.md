# Zen Browser Icon

Place the source PNG for the custom Zen Browser icon here:

```text
configs/zen/icon.png
```

Generate the ICNS file used by the Darwin module with:

```sh
scripts/make-zen-icon-icns.sh
```

The generated file should be:

```text
configs/zen/icon.icns
```

The `modules.desktop.apps.zen` module installs Zen via Homebrew and reapplies
`configs/zen/icon.icns` during activation and from a launchd agent. If the ICNS
file does not exist yet, activation succeeds and the icon step is skipped.

Best source image: a square 1024x1024 PNG with transparency if desired.
