#!/bin/bash
# =============================================================================
# uid1000 variant: this script is intentionally a no-op.
#
# The image is built with a fixed in-container account
# (UID=1000, GID=1000, name=uid1000), so no per-host UID/GID injection is
# needed. The file is kept so that VS Code's `initializeCommand` (and any
# external tooling that still calls it) does not break.
# =============================================================================
exit 0
