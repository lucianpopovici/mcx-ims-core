#!/bin/sh
# Gate: nothing depends on an entity (IMS-GEN-001; CONTRIBUTING.md,
# Architecture). Entities share code only through library crates, so each
# stays separately deployable and protocol code has one home.
# An entity is a workspace member with src/main.rs or a [[bin]] target.
# Fails if any workspace member, or fuzz/, depends on an entity in any
# dependency table ([dependencies], [dev-dependencies], [build-dependencies]
# and their [target.*] forms), by path or through [workspace.dependencies];
# if [workspace.dependencies] names an entity at all; or if a manifest
# cannot be read.
# Known misses: a dependency on an entity's code by another route than a
# Cargo dependency (an include!, a symlink, a copied file).
# Needs python3 >= 3.11 (tomllib), standard library only.
# Usage: entity_deps.sh [ROOT]
set -u
root=$(cd "${1:-$(dirname "$0")/../..}" && pwd)
exec python3 -I - "$root" <<'PY'
import pathlib, sys, tomllib

root = pathlib.Path(sys.argv[1]).resolve()
bad = []

def load(p):
    try:
        return tomllib.loads(p.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as e:
        bad.append(f"{p.relative_to(root)}: cannot read manifest: {e}")
        return None

ws = load(root / "Cargo.toml")
if ws is None:
    print("\n".join(bad), file=sys.stderr); sys.exit(1)
workspace = ws.get("workspace", {})

members = {}
for pattern in workspace.get("members", []):
    for d in sorted(root.glob(pattern)):
        if (d / "Cargo.toml").is_file():
            m = load(d / "Cargo.toml")
            if m is not None:
                members[d.resolve()] = m

entities = {d for d, m in members.items() if (d / "src" / "main.rs").is_file() or m.get("bin")}
wsdeps = workspace.get("dependencies", {})

def path_of(spec, base):
    if isinstance(spec, dict) and "path" in spec:
        return (base / spec["path"]).resolve()
    return None

for name, spec in wsdeps.items():
    p = path_of(spec, root)
    if p in entities:
        bad.append(f"Cargo.toml [workspace.dependencies]: {name} is an entity ({p.relative_to(root)})")

def tables(m):
    for k in ("dependencies", "dev-dependencies", "build-dependencies"):
        yield k, m.get(k, {})
    for cfg, t in m.get("target", {}).items():
        for k in ("dependencies", "dev-dependencies", "build-dependencies"):
            yield f"target.{cfg}.{k}", t.get(k, {})

crates = dict(members)
fuzz = root / "fuzz"
if (fuzz / "Cargo.toml").is_file():
    m = load(fuzz / "Cargo.toml")
    if m is not None:
        crates[fuzz.resolve()] = m

for d, m in sorted(crates.items()):
    for table, deps in tables(m):
        for name, spec in deps.items():
            if isinstance(spec, dict) and spec.get("workspace"):
                p = path_of(wsdeps.get(name), root)
            else:
                p = path_of(spec, d)
            if p in entities and p != d:
                bad.append(f"{(d / 'Cargo.toml').relative_to(root)} [{table}]: depends on entity {p.relative_to(root)}")

if bad:
    print("entity_deps: a crate depends on an entity:", file=sys.stderr)
    print("\n".join(bad), file=sys.stderr)
    sys.exit(1)
print(f"entity_deps: ok ({len(entities)} entities, {len(crates)} manifests)")
PY
