---
name: Pinball Hardware Log Reader
description: SSH to the pinball hardware server and read the latest MPF log. Use when debugging events, switch behavior, or light show triggers on real hardware.
---

# Pinball Hardware Log Reader

## When to use this skill
Use when:
- User wants to check real hardware MPF events
- Debugging what events fire on physical switches
- Verifying light shows, ball devices, or mode behavior on hardware
- User says "check the log" or "look at hardware logs"
- Service not starting or MPF errors on hardware

## Hardware server
- Host: 192.168.1.139
- SSH user: mike (sudo access)
- Service user: pinball (runs pinball.service — /opt/pinball must be owned by pinball:pinball)
- Log directory: /opt/pinball/logs/
- Service name: pinball.service (not mpf.service)

## Service management
```bash
# Check status
ssh mike@192.168.1.139 "systemctl status pinball.service --no-pager -l"

# View live output
ssh mike@192.168.1.139 "sudo journalctl -fu pinball.service"

# Fix permission issues (if files were written by mike user)
# Run on the machine directly:
# sudo chown -R pinball:pinball /opt/pinball
# sudo systemctl restart pinball.service

# Run MPF manually for debug output
ssh mike@192.168.1.139 "cd /opt/pinball && sudo -u pinball venv/bin/python -m mpf -c config_hardware.yaml"
```

## Standard commands

Find the latest log:
```bash
ssh mike@192.168.1.139 "ls -t /opt/pinball/logs/*.log | head -1"
```

Read the latest log (EventManager events only):
```bash
ssh mike@192.168.1.139 "grep 'EventManager : Event' \$(ls -t /opt/pinball/logs/*.log | head -1)"
```

Read full latest log:
```bash
ssh mike@192.168.1.139 "cat \$(ls -t /opt/pinball/logs/*.log | head -1)"
```

Filter for specific events (e.g. plunger/ball launch):
```bash
ssh mike@192.168.1.139 "grep -E '(EventManager : Event|SwitchController|ball_device|plunger)' \$(ls -t /opt/pinball/logs/*.log | head -1)"
```
