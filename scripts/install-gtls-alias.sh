#!/usr/bin/env bash
set -euo pipefail

BASHRC="${HOME}/.bashrc"
BEGIN_MARKER="# >>> gtls function >>>"
END_MARKER="# <<< gtls function <<<"
FUNCTION_BLOCK="$(cat <<'EOF'
# >>> gtls function >>>
gtls() {
  awk '
  BEGIN {
      RST = "\033[0m"
      RESTACK_HI = "\033[1;31m(needs restack)\033[0m"
  }

  function extract_ticket(s, up) {
      up = toupper(s)
      if (match(up, /\[[A-Z][A-Z]+-[0-9][0-9][0-9]*\]/)) {
          return substr(up, RSTART + 1, RLENGTH - 2)
      }
      if (match(up, /[A-Z][A-Z]+-[0-9][0-9][0-9]*/)) {
          return substr(up, RSTART, RLENGTH)
      }
      return ""
  }

  function extract_branch_token(s, arr, n, i) {
      n = split(s, arr, /[[:space:]]+/)
      for (i = 1; i <= n; i++) {
          if (arr[i] ~ /^[[:alnum:]_.-]+\/[[:alnum:]_.\/-]+$/ || arr[i] == "main") {
              return arr[i]
          }
      }
      return ""
  }

  FNR == NR {
      line = $0
      current_branch_candidate = extract_branch_token(line)
      if (current_branch_candidate != "") {
          current_branch = current_branch_candidate
      }

      if (current_branch != "" && match(line, /PR #[0-9]+/)) {
          if (match(line, /#[0-9]+/)) {
              pr_by_branch[current_branch] = substr(line, RSTART, RLENGTH)
          }
          title_ticket = extract_ticket(line)
          if (title_ticket != "") {
              ticket_by_branch[current_branch] = title_ticket
          }
      }
      next
  }

  {
      colored_line = $0
      plain_line = $0
      gsub(/\x1b\[[0-9;]*[A-Za-z]/, "", plain_line)

      branch = extract_branch_token(plain_line)

      if (!(branch in ticket_by_branch)) {
          branch_ticket = extract_ticket(branch)
          if (branch_ticket != "") {
              ticket_by_branch[branch] = branch_ticket
          }
      }

      if (index(plain_line, "(needs restack)") > 0) {
          gsub(/\(needs restack\)/, RESTACK_HI, colored_line)
      }

      suffix = ""
      if (branch in pr_by_branch) suffix = suffix " (" pr_by_branch[branch] ")"
      if (branch in ticket_by_branch) suffix = suffix " (" ticket_by_branch[branch] ")"

      printf "%s%s\n", colored_line, suffix
  }' \
  <(command gt log --no-interactive) \
  <(env -u NO_COLOR FORCE_COLOR=1 gt ls --no-interactive | command sed 's/[[:space:]]*$//')
}
# <<< gtls function <<<
EOF
)"

if [[ ! -f "${BASHRC}" ]]; then
  touch "${BASHRC}"
fi

if grep -q "^${BEGIN_MARKER}$" "${BASHRC}" && grep -q "^${END_MARKER}$" "${BASHRC}"; then
  sed -i.bak "/^${BEGIN_MARKER}$/,/^${END_MARKER}$/d" "${BASHRC}"
  echo "Replaced existing managed gtls function (backup: ${BASHRC}.bak)"
fi

if grep -q "^alias gtls=" "${BASHRC}"; then
  sed -i.bak "/^alias gtls=/d" "${BASHRC}"
  echo "Removed existing gtls alias from ${BASHRC}"
fi

# Insert after the header comment block, before the interactive guard if present.
if grep -q '^\[ -z "\$PS1" \] && return' "${BASHRC}"; then
  tmp="$(mktemp)"
  awk -v block="${FUNCTION_BLOCK}" '
    /^\[ -z "\$PS1" \] && return/ && !inserted {
      print block
      print ""
      inserted = 1
    }
    { print }
  ' "${BASHRC}" >"${tmp}"
  mv "${tmp}" "${BASHRC}"
else
  printf "\n%s\n" "${FUNCTION_BLOCK}" >>"${BASHRC}"
fi

echo "Installed gtls to ${BASHRC}"
echo "Open a new shell or run: source \"${BASHRC}\""
