set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

# controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`

[private]
default:
    just -l talos

