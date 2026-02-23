#!/usr/bin/env bash
set -euo pipefail

# Create a Hetzner Cloud server for Michael.
#
# Defaults match current production intent, but can be overridden:
#   SERVER_NAME=sleeper-service SERVER_TYPE=cpx11 LOCATION=hil SSH_KEY_NAME=Hetzner \
#     scripts/hetzner/create-server.sh
#
# Optional:
#   HCLOUD_TOKEN=... scripts/hetzner/create-server.sh

SERVER_NAME="${SERVER_NAME:-sleeper-service}"
SERVER_TYPE="${SERVER_TYPE:-cpx11}"
LOCATION="${LOCATION:-hil}" # US West (Hillsboro)
SSH_KEY_NAME="${SSH_KEY_NAME:-Hetzner}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

require hcloud
require python3

if ! hcloud server list >/dev/null 2>&1; then
  echo "ERROR: hcloud auth failed. Set HCLOUD_TOKEN or configure hcloud context." >&2
  exit 1
fi

SERVER_ARCH="$(
  hcloud server-type describe "$SERVER_TYPE" -o json | python3 -c '
import json,sys
obj=json.load(sys.stdin)
arch=obj.get("architecture")
if arch not in ("x86", "arm"):
    raise SystemExit(f"Unsupported or unknown server type architecture: {arch}")
print(arch)
'
)"

# Image preference:
# 1) latest non-deprecated NixOS
# 2) latest deprecated NixOS (with --allow-deprecated-image=true)
# 3) fallback to Debian (prefer debian-13, else newest debian-*)
IMAGE_INFO="$(
  hcloud image list -a "$SERVER_ARCH" -o json | python3 -c '
import json,re,sys
imgs=json.load(sys.stdin)

nixos_non_dep=[]
nixos_dep=[]
debian_non_dep=[]

for i in imgs:
    name=str(i.get("name", ""))
    desc=str(i.get("description", ""))
    text=" ".join(str(i.get(k,"")) for k in ("name","description","os_flavor","os_version")).lower()

    m=re.search(r"(\d{2}\.\d{2})", text)
    ver=tuple(map(int,m.group(1).split("."))) if m else (0,0)
    created=i.get("created","")
    entry=(ver, created, str(i["id"]), name, desc)

    if "nixos" in text:
        (nixos_dep if i.get("deprecated") else nixos_non_dep).append(entry)

    if name.startswith("debian-") and (not i.get("deprecated")):
        debian_non_dep.append(entry)

if nixos_non_dep:
    nixos_non_dep.sort()
    _, _, image_id, name, desc = nixos_non_dep[-1]
    print(f"nixos|{image_id}|false|{name}|{desc}")
elif nixos_dep:
    nixos_dep.sort()
    _, _, image_id, name, desc = nixos_dep[-1]
    print(f"nixos-deprecated|{image_id}|true|{name}|{desc}")
elif debian_non_dep:
    debian13 = [e for e in debian_non_dep if e[3] == "debian-13"]
    pick = sorted(debian13 or debian_non_dep)[-1]
    _, _, image_id, name, desc = pick
    print(f"debian-fallback|{image_id}|false|{name}|{desc}")
else:
    raise SystemExit(
        "No usable NixOS or Debian image found in this project. "
        "Run: hcloud image list -o columns=id,name,description,deprecated,type,created"
    )
'
)"

IFS='|' read -r IMAGE_STRATEGY IMAGE_ID ALLOW_DEPRECATED_IMAGE IMAGE_NAME IMAGE_DESC <<< "$IMAGE_INFO"

echo "Creating server..."
echo "  name:      $SERVER_NAME"
echo "  type:      $SERVER_TYPE"
echo "  location:  $LOCATION"
echo "  ssh key:   $SSH_KEY_NAME"
echo "  arch:      $SERVER_ARCH"
echo "  image id:  $IMAGE_ID"
echo "  image:     $IMAGE_NAME"
if [[ -n "${IMAGE_DESC:-}" ]]; then
  echo "  image desc:$IMAGE_DESC"
fi
if [[ "$IMAGE_STRATEGY" == "debian-fallback" ]]; then
  echo "WARN: no NixOS image available in this project; using Debian bootstrap image"
fi

create_args=(
  --name "$SERVER_NAME"
  --type "$SERVER_TYPE"
  --location "$LOCATION"
  --image "$IMAGE_ID"
  --ssh-key "$SSH_KEY_NAME"
  --label app=michael
  --label managed-by=nix-config
)

if [[ "$ALLOW_DEPRECATED_IMAGE" == "true" ]]; then
  echo "WARN: only deprecated NixOS images found; allowing deprecated image"
  create_args+=(--allow-deprecated-image=true)
fi

hcloud server create "${create_args[@]}"

echo
echo "Current servers:"
hcloud server list
