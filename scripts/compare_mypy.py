#!/usr/bin/env python3
import configparser
import json

# Read configurations
root_cfg = configparser.ConfigParser()
root_cfg.read('mypy.ini')

fix_cfg = configparser.ConfigParser()
fix_cfg.read('mypy_fix/mypy.ini')

# Compare configurations
delta = {}
for section in fix_cfg.sections():
    if section not in root_cfg.sections():
        delta[section] = dict(fix_cfg[section])
    else:
        section_delta = {}
        for option in fix_cfg[section]:
            if option not in root_cfg[section] or fix_cfg[section][option] != root_cfg[section][option]:
                section_delta[option] = fix_cfg[section][option]
        if section_delta:
            delta[section] = section_delta

# Generate comparison report
result = {
    "root_sections": list(root_cfg.sections()),
    "fix_sections": list(fix_cfg.sections()),
    "delta": delta
}

# Write to JSON file
with open('scripts/mypy_delta.json', 'w') as f:
    json.dump(result, indent=2, fp=f)