---
name: MPF Virtual Test Runner
description: Runs MPF pinball framework in virtual mode and helps debug switches, ball devices, and config issues. Use when user is testing MPF configs or reporting MPF runtime/eject/switch problems.
---

# MPF Virtual Test Runner

## When to use this skill
Use when:
- Running MPF locally or in CI
- User mentions config_virtual.yaml
- Debugging switch, coil, or ball device behavior
- Eject failures, plunger issues, or missing device errors

## Standard command
Always run:

```bash
mpf -c config_virtual.yaml -t

