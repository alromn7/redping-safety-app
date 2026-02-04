# Development Workspace Setup (Multi-Root)

## Overview
This workspace links the main RedPing system with the new apps:
- Main system: C:/flutterapps/redping_14v
- RedPing Emergency app: C:/flutterapps/redping_emergency_app
- RedPing SAR app: C:/flutterapps/redping_sar_app

## Open the Workspace
1. In VS Code, open: C:/flutterapps/redping_14v/redping_14v.code-workspace
2. Folders pane will show all three roots.

## Recommendations
- Keep planning-only changes until the split plan phases start.
- Use feature flags and `AppVariant` in the main system for dry-run separation logic.
- Do not run builds yet; confirm IDs, Firebase strategy, and subscriptions.

## Later (when ready to try)
Android/iOS flavor targets and env keys should be configured in each app before running. When approved, build commands will be documented in app-specific READMEs.
