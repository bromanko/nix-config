# Move Jellyfin to native macOS with shared TubeArchivist media

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

## Purpose / Big Picture

Jellyfin currently runs inside Docker Desktop on the Apple Silicon Gray Area Mac mini.
When an iPad cannot play a TubeArchivist AV1 file directly, containerized Jellyfin must
transcode it in software because Docker Desktop cannot expose Apple's VideoToolbox media
engine to its Linux virtual machine. Recorded 1080p60 playback sessions transcoded at
about 0.68 times real time, exhausted the client buffer, and froze.

After this change, Jellyfin runs as a native macOS launch daemon installed by nix-darwin.
It uses Nixpkgs' VideoToolbox-enabled FFmpeg and reads a normal host media directory.
TubeArchivist, Redis, and Elasticsearch remain in their upstream-supported Docker
configuration. TubeArchivist writes through a bind mount to the host media directory,
and native Jellyfin reads that same directory without a second copy. An operator can
prove the outcome by downloading a test video, seeing it in Jellyfin, playing it from an
iPad, and observing either direct play or a VideoToolbox transcode faster than real time.

## Problem Framing and Constraints

The current Docker media volume contains about 321 GiB, while the host initially has
about 139 GiB free. The operator has explicitly chosen to discard the existing media and
start over, so no large data migration is required. Deleting the existing media-server
volumes is destructive and must occur only after the replacement configurations build
and a native smoke test passes. Unrelated Docker containers, images, and volumes must not
be removed.

TubeArchivist supports Docker as its only official installation method. Repackaging its
Django backend, Celery workers, frontend, Nginx, Redis, and Elasticsearch for native
macOS is out of scope. Keeping TubeArchivist containerized does not affect Jellyfin's
transcoding path.

## Strategy Overview

Add a small nix-darwin module that installs Nixpkgs Jellyfin, creates mutable host
runtime directories, and runs Jellyfin as a hidden service user from a system launch
daemon. The service user owns Jellyfin state but has only read access to TubeArchivist
media. A system launch daemon starts at boot without requiring an interactive login. Keep the
module disabled on Gray Area until cutover so it cannot contend with Docker Jellyfin for
port 8096.

Prepare an additive next-generation Compose file in the sibling `media-server`
repository. It removes Jellyfin, replaces the Docker media volume with a host bind mount,
and retains named volumes only for Redis and Elasticsearch. Validate this file without
starting it. At cutover, stop the old stack, explicitly delete only its six volumes,
confirm Docker's sparse disk image releases space, promote the prepared Compose file,
enable native Jellyfin, and start both halves.

## Alternatives Considered

Keeping Jellyfin in Docker and forcing TubeArchivist to download H.264 would avoid many
transcodes, but it would leave the server unable to handle incompatible existing or
future media reliably. Native Jellyfin has already demonstrated the required hardware
path and is the more complete fix.

Running the full stack in a NixOS virtual machine would remain unable to access the M4
media engine. Running TubeArchivist natively is unsupported upstream and would create a
large maintenance burden. Both alternatives are rejected.

Migrating the old media would preserve downloads but requires staged sparse-disk
reclamation or an external disk. The operator chose a fresh start, which is simpler and
avoids retaining files downloaded in formats that trigger iPad transcoding.

## Risks and Countermeasures

The destructive volume deletion could target unrelated data. Before deletion, list the
exact `media-server_*` volume names and compare them to the six names in this plan. Use
explicit names rather than a global prune. Capture before-and-after `docker system df`
and host disk usage. Stop if any expected name differs.

Native Jellyfin could fail to start at boot because its mutable directories or log files
do not exist. The nix-darwin activation script creates every directory with the primary
user and `staff` ownership before launchd loads the daemon. A smoke test exercises the
same Nix package before cutover.

The new Compose stack could write to an inaccessible bind mount. Create the host
TubeArchivist media and cache directories before startup, then use a disposable file
write from a container and verify the primary user can read and delete it before
allowing downloads.

Jellyfin and Docker Jellyfin both use port 8096. The module remains disabled until the
old container has been stopped and removed. Acceptance includes proving exactly one
listener owns that port.

A new TubeArchivist release or Elasticsearch version could be incompatible. The prepared
Compose file pins TubeArchivist 0.5.10, Elasticsearch 8.19.0, and Redis 8.2 Alpine. The
Elasticsearch image and version follow TubeArchivist's current ARM64 documentation.

## Progress

- [x] (2026-07-16 17:12Z) Diagnosed Docker software transcoding and measured two failing sessions at about 0.68 times real time.
- [x] (2026-07-16 17:12Z) Verified Nixpkgs Jellyfin 10.11.11 and its FFmpeg support VideoToolbox on aarch64-darwin.
- [x] (2026-07-16 17:12Z) Transcoded an affected AV1 1080p60 sample through native HEVC VideoToolbox at 3.5 times real time.
- [x] (2026-07-16 17:12Z) Chose a fresh media-server installation with native Jellyfin and containerized TubeArchivist.
- [x] (2026-07-16 17:12Z) Added the disabled native Jellyfin module and an additive replacement Compose file.
- [x] (2026-07-16 17:18Z) Formatted, evaluated, and built both disabled and synthetically enabled native Jellyfin host configurations.
- [x] (2026-07-16 17:18Z) Validated the replacement three-service, two-volume Compose model without starting containers.
- [x] (2026-07-16 17:18Z) Ran native Jellyfin on port 8097 with disposable state; it reached `Healthy`, detected VideoToolbox, and stopped cleanly.
- [x] (2026-07-16 17:19Z) Obtained explicit operator confirmation immediately before destructive cutover.
- [x] (2026-07-16 17:23Z) Stopped the old stack and deleted exactly its six project volumes while retaining unrelated Docker volumes.
- [x] (2026-07-16 17:24Z) Verified Docker released the deleted media space and created/tested the host bind-mount directories.
- [x] (2026-07-16 17:37Z) Promoted and started the replacement TubeArchivist Compose stack; all configured hostnames return health `"OK"`.
- [x] (2026-07-16 18:01Z) Enabled and activated native Jellyfin as a hidden `_jellyfin` launch daemon with read-only access to TubeArchivist media.
- [ ] Complete extended iPad acceptance (completed: seventeen H.264/AAC 1080p downloads verified; a live Jellyfin iOS session reported `DirectPlay`, no FFmpeg process, and advanced 20.1 seconds normally; remaining: operator confirms representative long playback does not freeze).
- [x] (2026-07-16 19:31Z) Added and tested API-aware TubeArchivist retention with a 200 GiB trigger and 180 GiB low-water mark.
- [x] (2026-07-16 19:37Z) Activated the hourly retention launch agent; its first run measured 17.43 GiB against the 200/180 GiB policy and exited successfully without deletion.

## Surprises & Discoveries

- Observation: The old media is not duplicated between TubeArchivist and Jellyfin.
  Evidence: Both containers mount the same `media-server_media` volume, writable at
  `/youtube` for TubeArchivist and read-only at `/media` for Jellyfin.

- Observation: The Nixpkgs Jellyfin package is a native Darwin package rather than a
  Linux wrapper.
  Evidence: Its bundled FFmpeg lists `videotoolbox`, `h264_videotoolbox`, and
  `hevc_videotoolbox` on Gray Area.

- Observation: The current Docker media volume accounts for nearly all Docker disk use.
  Evidence: Docker reports roughly 344.5 GB for `media-server_media` and the sparse
  `Docker.raw` file occupies roughly 375 GB on the host.

- Observation: A fresh Jellyfin health endpoint reports `Degraded` while first-run database migrations and startup tasks are still running.
  Evidence: The first smoke test reached the endpoint immediately, then logged `Startup complete` about ten seconds later. Waiting for body `Healthy` produced a clean startup and SIGTERM shutdown.

- Observation: A Nix path produced by `nix build --no-link` is not a persistent garbage-collector root.
  Evidence: The first smoke-test command used a previously printed store path that had already been collected. Rebuilding and resolving the package path inside the test made the run repeatable.

- Observation: Docker Desktop reclaimed deleted named-volume blocks automatically and quickly.
  Evidence: After the six volume deletions, `Docker.raw` fell from 375 GB to 54 GB in under five seconds and host free space rose from 122 GiB to 443 GiB.

- Observation: TubeArchivist validates the HTTP Host header against `TA_HOST` even on its health route.
  Evidence: A probe addressed as `127.0.0.1:8000` returned HTTP 400, while the configured `localhost:8000`, `gray-area:8000`, and `gray-area.local:8000` hosts each returned `"OK"`.

- Observation: This noninteractive harness has no cached administrator credential for nix-darwin activation.
  Evidence: The enabled system derivation builds, but `sudo -n true` fails. The operator performed the required `darwin-rebuild switch` steps from an interactive terminal.

- Observation: The TubeArchivist Jellyfin plugin explicitly requires Jellyfin media access to be read-only.
  Evidence: The plugin README warns that write access can let Jellyfin operations break TubeArchivist. The daemon now runs as hidden UID/GID 383; POSIX evaluation shows read and traverse permission but no write permission on the host `youtube` directory.

- Observation: Making all Jellyfin state private to the service account also hid diagnostics from the operator.
  Evidence: Mode 0750 `_jellyfin:_jellyfin` prevented the primary user from traversing the logs directory. State now uses `_jellyfin:staff` mode 0750, preserving Jellyfin-only writes while allowing the administrator to read logs and backups.

- Observation: Application and integration configuration is valid and produces direct-play media for the iPad.
  Evidence: TubeArchivist stores the requested H.264/AAC format selector; seventeen inspected downloads are H.264 1080p with AAC stereo; Jellyfin has VideoToolbox enabled for H.264, HEVC, and AV1; plugin 1.4.4 returns HTTP 200 with `pong` from TubeArchivist 0.5.10; the YouTube Shows library selects only TubeArchivist providers. A live Jellyfin iOS session for Roman reported `DirectPlay`, had no FFmpeg process, and advanced from 38.9 to 59.0 seconds over a 20-second observation.

## Decision Log

- Decision: Run Jellyfin natively but retain TubeArchivist, Redis, and Elasticsearch in Docker.
  Rationale: Only Jellyfin needs the M4 media engine, while Docker is TubeArchivist's only supported deployment.
  Date: 2026-07-16

- Decision: Share media with a host bind mount rather than a Docker named volume.
  Rationale: Both the container and native process can address one physical copy of each file.
  Date: 2026-07-16

- Decision: Start fresh rather than migrate the existing media and application state.
  Rationale: The operator accepts losing the current archive, and fresh storage avoids a risky 321 GiB staged move.
  Date: 2026-07-16

- Decision: Install Jellyfin as a system launch daemon running as a dedicated hidden service user.
  Rationale: It starts after reboot without a graphical login, cannot alter TubeArchivist media, and owns only its mutable application state. The state group is `staff` so the primary administrator can inspect logs and backups.
  Date: 2026-07-16

- Decision: Prepare a second Compose file before replacing the active one.
  Rationale: Validation stays non-destructive and an accidental `docker compose up` against the current file cannot switch TubeArchivist to an empty host directory early.
  Date: 2026-07-16

- Decision: Enforce a 200 GiB media ceiling with an hourly API retention job that trims to 180 GiB.
  Rationale: TubeArchivist only auto-deletes watched videos and the plugin can sync watched state from one Jellyfin user, so neither feature bounds unwatched subscription growth. API deletion preserves TubeArchivist's index; the 20 GiB hysteresis avoids repeated small cleanup runs. Watched videos are selected first, then the oldest published videos. If over-limit cleanup fails, the job stops TubeArchivist rather than risk filling the host filesystem.
  Date: 2026-07-16

## Outcomes & Retrospective

Feasibility, preparation, and the Docker half of the destructive cutover are complete.
Native Nix FFmpeg processed the exact problematic format at 3.5 times real time. The
replacement TubeArchivist stack is healthy on the new host bind mounts, and the old 321
GiB archive and application volumes are gone as authorized. Automatic sparse-disk
reclamation returned about 321 GiB to the host without touching unrelated Docker data.

The native Jellyfin launch daemon is active and healthy on port 8096 under hidden UID
383. It detects VideoToolbox H.264 and HEVC encoders through the Nix FFmpeg package.
The shared media directory is readable and traversable but not writable by Jellyfin;
Jellyfin state is writable by the daemon and readable by the primary administrator.
TubeArchivist remains healthy on port 8000. Both applications, the integration plugin,
and the Shows library are configured. Inspected downloads use compatible H.264 1080p
video and AAC stereo audio. A live iPad session used `DirectPlay`, required no FFmpeg
process, and advanced normally during observation. The hourly retention agent is active
with a 200 GiB trigger and 180 GiB target; its first 17.43 GiB check exited zero without
calling deletion. Only the operator's extended no-freeze playback confirmation remains.

## Context and Orientation

The `nix-config` repository automatically imports every Nix module below
`modules/darwin/` into Darwin hosts. `hosts/aarch64-darwin/gray-area/default.nix` enables
modules for the Mac mini. The new `modules/darwin/services/jellyfin.nix` module owns the
native package, hidden service account, mutable directories, log rotation, and launch
daemon. Gray Area enables this module.

The sibling `media-server` repository contains the currently active
`../media-server/docker-compose.yaml`. The additive
`../media-server/docker-compose.next.yaml` describes the replacement stack. The old file
continues to describe running containers until the destructive cutover.

A bind mount maps a normal host directory into a container. TubeArchivist sees the host
media directory as `/youtube`; Jellyfin uses the host path directly. Redis and
Elasticsearch still use Docker named volumes because native Jellyfin never reads their
data.

## Preconditions and Verified Facts

Gray Area is an Apple M4 Mac mini with 24 GB physical memory. Docker Desktop assigns its
Linux VM 10 CPUs and about 8 GB memory. Nixpkgs currently provides Jellyfin 10.11.11 and
Jellyfin FFmpeg 7.1.4-3 for aarch64-darwin. The package wrapper supplies the matching web
client and FFmpeg automatically.

The current Compose project is named `media-server`. Its six project volumes are
`media-server_media`, `media-server_cache`, `media-server_redis`, `media-server_es`,
`media-server_jellyfin-config`, and `media-server_jellyfin-cache`. Other volumes such as
the Scherzo Nix cache and GitHub runner data are unrelated and must remain untouched.

The `nix-config` working copy was clean when this work began. The `media-server` working
copy already contained an unrelated added Claude settings file and an untracked Jellyfin
configuration backup; this work must not modify or commit either artifact.

## Scope Boundaries

This work adds native Jellyfin, replaces only the TubeArchivist stack's storage layout,
performs a fresh configuration of both applications, and bounds new media growth with an
API-aware retention job. It does not migrate media, users, watch history, TubeArchivist
subscriptions, cookies, playlists, Redis data, or Elasticsearch indices. It does not
change Docker Desktop itself or delete unrelated Docker resources. Retention deletes
only when the shared media directory exceeds 200 GiB; it never removes files directly.

The TubeArchivist metadata plugin remains part of the desired integration, but its
installation and settings occur through Jellyfin's setup UI after both servers run. A
fully declarative Jellyfin database or plugin configuration is explicitly deferred
because Jellyfin owns mutable database state and exposes these settings through its
administration API and UI.

## Milestones

The first milestone prepares both configurations without affecting running services.
It ends when the Nix module evaluates and the replacement Compose file parses with the
expected three services, two named volumes, and two host bind mounts.

The second milestone proves the native server lifecycle with disposable state on an
alternate port. It ends when the HTTP health endpoint responds, the logs identify the
Nix FFmpeg path, and stopping the process removes the listener. No production data or
ports change.

The third milestone is the destructive cutover. It starts only after explicit operator
confirmation. It stops the old stack, removes exactly six project volumes, verifies host
space recovery, promotes the replacement Compose file, and starts TubeArchivist. This
milestone is irreversible for the discarded application state.

The fourth milestone enables the prepared nix-darwin module and completes application
setup. It ends with one downloaded video visible in both applications and native
Jellyfin starting automatically after a service restart.

The final milestone validates the user outcome. An iPad must play a representative video
without freezing. If direct play is unavailable, Jellyfin logs must show a VideoToolbox
encoder and a transcode speed greater than 1.0 times real time.

## Plan of Work

In `modules/darwin/services/jellyfin.nix`, define
`modules.services.jellyfin.enable`, `stateDir`, and `mediaDir`. When enabled, install
`pkgs.jellyfin`, create a hidden service account plus data, config, cache, log, and media
directories during system activation, and declare `launchd.daemons.jellyfin`. The daemon
must invoke the packaged `jellyfin` wrapper with explicit mutable directory arguments,
run as the service account, restart on failure, and write bounded stdout and stderr
logs. Jellyfin state uses the `staff` group for operator-readable diagnostics, while the
host media directory remains owned by the primary user and non-writable by the daemon.

In `../media-server/docker-compose.next.yaml`, declare only `tubearchivist`,
`archivist-redis`, and `archivist-es`. Bind the configurable host media root's `youtube`
and TubeArchivist cache directories. Require passwords through Compose environment
substitution instead of committing them. Pin ARM64-compatible images and retain named
volumes only for Redis and Elasticsearch. Add `.env` to
`../media-server/.gitignore`.

After non-destructive validation, create disposable Jellyfin config with internal and
public HTTP port 8097. Start the Nix package manually with disposable data, config,
cache, and logs. Query its health endpoint, inspect logs and FFmpeg capabilities, then
stop it and remove the disposable directories.

At cutover, use the old Compose file to stop and remove containers before editing the
canonical file. Explicitly remove the six known project volumes and verify the named
media volume no longer appears. Wait for Docker's `Docker.raw` sparse file to shrink; if
host free space does not rise, issue a filesystem trim inside the Docker Desktop VM
without deleting any further Docker objects.

Promote the prepared Compose file to `../media-server/docker-compose.yaml`, create a
mode-0600 `.env` with fresh random TubeArchivist and Elasticsearch passwords, pull the
pinned images, and start the three services. Enable `modules.services.jellyfin` in the
Gray Area host and apply nix-darwin interactively. Complete setup and acceptance tests.

## Concrete Steps

From the `nix-config` repository root, format and parse the new module:

    nixfmt modules/darwin/services/jellyfin.nix
    nix-instantiate --parse modules/darwin/services/jellyfin.nix

Evaluate the disabled module as part of the normal host, then synthetically enable it to
inspect the launch arguments. Build the current host to prove automatic module imports
remain valid:

    nix build '.#darwinConfigurations.gray-area.system'

From the sibling `media-server` repository, validate the replacement model without
creating directories, networks, volumes, or containers:

    TA_PASSWORD=validation-only ELASTIC_PASSWORD=validation-only \
      docker compose -f docker-compose.next.yaml config --quiet
    TA_PASSWORD=validation-only ELASTIC_PASSWORD=validation-only \
      docker compose -f docker-compose.next.yaml config --services
    TA_PASSWORD=validation-only ELASTIC_PASSWORD=validation-only \
      docker compose -f docker-compose.next.yaml config --volumes

Expect services `archivist-es`, `archivist-redis`, and `tubearchivist`, and volumes `es`
and `redis`. Jellyfin and a media volume must not appear.

For the smoke test, create disposable directories under `/tmp`, write a minimal
`network.xml` selecting port 8097, start the packaged Jellyfin binary in the background,
and poll:

    curl --fail http://127.0.0.1:8097/health

Expect HTTP 200 and body `Healthy`. Inspect the server log for Jellyfin 10.11.11 and the
Nix store FFmpeg path. Terminate the exact background process, verify port 8097 has no
listener, and delete the disposable tree.

Stop after this checkpoint and request final confirmation. Do not run volume deletion,
Compose promotion, or nix-darwin activation without it.

## Testing and Falsifiability

Nix parsing catches syntax errors. Building the Gray Area system catches invalid options,
automatic import failures, package platform failures, malformed launchd property lists,
and activation script evaluation errors. Synthetic enabled evaluation must show the
Jellyfin wrapper followed by `--service`, `--datadir`, `--configdir`, `--cachedir`, and
`--logdir`.

Compose model validation must fail if either password variable is absent. With validation
values present, it must list exactly three services and two named volumes. Rendered
TubeArchivist mounts must include one host path ending in `youtube` mapped to `/youtube`
and one ending in `tubearchivist/cache` mapped to `/cache`.

The native smoke test disproves lifecycle feasibility if health does not become ready
within 60 seconds, if logs omit VideoToolbox from available hardware acceleration types,
or if the process cannot be stopped cleanly. The direct FFmpeg performance test already
disproves the performance claim if a repeat falls below 1.0 times real time; its measured
baseline is 3.5 times.

Final acceptance disproves the user outcome if an iPad freezes, if an incompatible video
uses `libx264` or `libx265` instead of a VideoToolbox encoder, or if reported transcode
speed falls below 1.0 times real time.

## Validation and Acceptance

Before cutover, acceptance requires a successful Gray Area system build, a valid
three-service Compose model, a native health response on port 8097, and no change to the
running containers or six existing volumes.

After cutover, `docker ps` must show healthy TubeArchivist plus running Redis and
Elasticsearch, but no Jellyfin container. `launchctl print system/org.nix-darwin.jellyfin`
must report a running native process. Ports 8000 and 8096 must each have exactly one
listener. A file created by TubeArchivist under `/youtube` must appear in the host media
directory and be readable by Jellyfin.

The complete change is accepted when a newly downloaded video appears with metadata in
Jellyfin and plays on an iPad through at least ten minutes without a freeze. A forced
transcode must use VideoToolbox and remain faster than real time.

## Rollout, Recovery, and Idempotence

Preparation is additive and does not affect the running stack. The smoke test uses only
disposable state and an alternate port. Repeating formatting, builds, Compose config
rendering, and the smoke test is safe.

Before volume deletion, rollback means discard the new module and next Compose file; the
old stack remains unchanged. After deletion, old application state cannot be restored
without an external backup. The operator has accepted that loss, but the deletion still
requires a final confirmation at the command boundary.

If replacement TubeArchivist fails after deletion, keep its new host media directory and
fix or roll back only image/configuration versions; do not delete newly downloaded
files. If native Jellyfin fails, disable its host option and temporarily add the old
Jellyfin container definition pointed at the new host bind mount. This restores software
transcoding while preserving the new media layout.

The activation script and Compose startup are idempotent. Directory creation preserves
existing contents, and repeated `docker compose up -d` reconciles rather than duplicates
services. The retention job takes a nonblocking lock so overlapping launchd invocations
do not duplicate deletion. Below 200 GiB it does not read the API token or call the API.
Above the limit, any API, index, or filesystem inconsistency fails closed and stops the
TubeArchivist container. Recovery is to inspect the retention error log, correct the
problem, free space through TubeArchivist if needed, and run `docker compose up -d` from
the sibling media-server repository.

## Artifacts and Notes

The decisive pre-change FFmpeg evidence was:

    Docker: libx265, 1080p60 AV1 input, speed=0.679x
    Native: hevc_videotoolbox, same input, speed=3.50x

The six volume names at the start of the work were:

    media-server_media
    media-server_cache
    media-server_redis
    media-server_es
    media-server_jellyfin-config
    media-server_jellyfin-cache

## Interfaces and Dependencies

`modules/darwin/services/jellyfin.nix` exposes these nix-darwin options:

    modules.services.jellyfin.enable: boolean
    modules.services.jellyfin.stateDir: string
    modules.services.jellyfin.mediaDir: string

The module depends on `pkgs.jellyfin`. Its package wrapper supplies matching
`jellyfin-web` and `jellyfin-ffmpeg`, so the launch daemon must invoke the wrapper rather
than the unwrapped .NET executable.

`modules/darwin/services/tubearchivist-retention.nix` exposes:

    modules.services.tubearchivistRetention.enable: boolean
    modules.services.tubearchivistRetention.mediaDir: string
    modules.services.tubearchivistRetention.stateDir: string
    modules.services.tubearchivistRetention.tokenFile: string
    modules.services.tubearchivistRetention.baseUrl: string
    modules.services.tubearchivistRetention.containerName: string
    modules.services.tubearchivistRetention.maximumGiB: positive integer
    modules.services.tubearchivistRetention.targetGiB: positive integer
    modules.services.tubearchivistRetention.intervalSeconds: positive integer

The module runs `pkgs.my.tubearchivist-retention` hourly as the primary user. Its API
token is a mode-0600 runtime file outside Git and the Nix store. Unit tests specify that
watched videos precede unwatched videos, older publications precede newer ones, dry runs
never call DELETE, pagination is complete and deduplicated, and failures stop cleanup.

The replacement Compose stack depends on Docker Desktop, TubeArchivist 0.5.10,
Elasticsearch 8.19.0, and Redis 8.2 Alpine. It accepts `MEDIA_SERVER_ROOT`, `TA_HOST`,
`TA_USERNAME`, `TA_PASSWORD`, and `ELASTIC_PASSWORD` through Compose substitution. The
two passwords are runtime secrets and must never be committed to either repository or
the Nix store.
