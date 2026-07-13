#!/bin/sh
# Pretty-print tailscale status: IP, owner DisplayName (fallback LoginName), OS, status.
# Rows sorted with online peers first, then by Tailscale IP. Requires jq (1.5+).
# Offline "last seen" times are shown in IST (Asia/Kolkata); Tailscale sends UTC.
set -eu

TAILSCALE_BIN="${TAILSCALE_CMD:-tailscale}"

if ! command -v jq >/dev/null 2>&1; then
	echo "Note: install jq for this view; showing default status." >&2
	exec "$TAILSCALE_BIN" status
fi

"$TAILSCALE_BIN" status --json | TZ=Asia/Kolkata jq -r '
	. as $root
	| ([$root.Self] + ($root.Peer | to_entries | map(.value)))
	| sort_by([if .Online then 0 else 1 end, .TailscaleIPs[0]])
	| .[]
	| . as $p
	| [
		($p.TailscaleIPs[0] // "-"),
		(
			($root.User[($p.UserID | tostring)] // empty)
			| if . == null then ($p.UserID | tostring)
				else (.DisplayName // .LoginName // ($p.UserID | tostring))
				end
		),
		($p.OS // "-"),
		(
			if ($p.Online | not) then
				if ($p.LastSeen != null and $p.LastSeen != "0001-01-01T00:00:00Z") then
					"offline, last seen " + ($p.LastSeen | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 | localtime | strftime("%Y-%m-%d %H:%M:%S")) + " IST"
				else "offline" end
			elif $p.Active then
				(if ($p.CurAddr != null and $p.CurAddr != "") then
					"active; direct " + $p.CurAddr
				elif ($p.Relay != null and $p.Relay != "") then
					"active; relay " + $p.Relay
				else "active" end)
				+ ", tx " + ($p.TxBytes | tostring) + " rx " + ($p.RxBytes | tostring)
			else "-" end
		)
	]
	| @tsv
' | column -t -s "	"
