#!/usr/bin/env bash
# scaffold.sh: copy the fixture project into the empty eval workspace and
# commit it, so the audit sees a normal git repository.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
cp -R "$here/repo/." .
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "fixture"
