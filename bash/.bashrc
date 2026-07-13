# ~/.bashrc: executed by bash(1) for non-login shells.
# Synced from dotfiles — see https://github.com/manikuttan-mm1/dotfiles

# gt must be on PATH for gtls in non-interactive shells (e.g. Cursor agent terminals)
if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:${HOME}/.local/bin:${PATH}"
else
  export PATH="${HOME}/.local/bin:${PATH}"
fi

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

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
    else
    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

export PATH="/usr/bin:$PATH"
export GOPATH="${HOME}/go"
export PATH="${PATH}:${GOPATH}/bin"

# Go: set GOROOT if you install Go under ~/sdk (uncomment and adjust version)
# export GOROOT="${HOME}/sdk/go1.26.2.linux-amd64/go"
# export PATH="${GOROOT}/bin:${PATH}"

alias prettyjson='python -m json.tool'
alias calw="gcalcli calw"
alias calm="gcalcli calm"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

alias linter="${GOPATH}/bin/golangci-lint run"

function run_mysql() {
    if [ "$(sudo docker ps -q -f name=mysql-container)" ]; then
        sudo docker stop mysql-container
    fi

    if [ "$(sudo docker ps -aq -f name=mysql-container)" ]; then
        sudo docker rm mysql-container
    fi

    sudo docker run --name mysql-container \
    -e MYSQL_ROOT_PASSWORD=root \
    -d \
    -p 3306:3306 \
    -v mysql_data:/var/lib/mysql \
    mysql:latest
}

load_mysql_csv() {
    echo -e "\n"
    echo "Steps to Load a CSV File into MySQL via Docker:"
    echo "1. Copy the CSV file to the MySQL container:"
    echo "   sudo docker cp /path/to/your/file.csv mysql-container:/var/lib/mysql-files/"
    echo ""
    echo "2. Load the CSV into MySQL:"
    echo "   docker exec -it mysql-container mysql -u your_username -p -e \""
    echo "   LOAD DATA INFILE '/var/lib/mysql-files/file.csv'"
    echo "   INTO TABLE your_table"
    echo "   FIELDS TERMINATED BY ','"
    echo "   ENCLOSED BY '\"'"
    echo "   LINES TERMINATED BY '\\n'"
    echo "   IGNORE 1 ROWS;  -- Use this if your CSV has a header row"
    echo -e "\n"
}

function csv_to_mysql() {
    local csv_file="$1"
    if [[ -z "$csv_file" ]]; then
        echo "Usage: csv_to_mysql /path/to/csv_file.csv"
        return 1
    fi

    python3 "${HOME}/bin/csv_to_mysql.py" "$csv_file"
}

function excel_to_mysql() {
    local excel_file="$1"
    if [[ -z "$excel_file" ]]; then
        echo "Usage: excel_to_mysql /path/to/excel_file.xlsx"
        return 1
    fi

    python3 "${HOME}/bin/excel_to_mysql.py" "$excel_file"
}

###-begin-gt-completions-###
_gt_yargs_completions()
{
    local cur_word args type_list

    cur_word="${COMP_WORDS[COMP_CWORD]}"
    args=("${COMP_WORDS[@]}")

    type_list=$(gt --get-yargs-completions "${args[@]}")

    COMPREPLY=( $(compgen -W "${type_list}" -- ${cur_word}) )

    if [ ${#COMPREPLY[@]} -eq 0 ]; then
      COMPREPLY=()
    fi

    return 0
}
complete -o bashdefault -o default -F _gt_yargs_completions gt
###-end-gt-completions-###

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

alias pbpaste="xclip -selection clipboard -o"

if [ -d "$HOME/.config/fabric/patterns" ]; then
  for pattern_file in "$HOME"/.config/fabric/patterns/*; do
      [ -f "$pattern_file" ] || continue
      pattern_name=$(basename "$pattern_file")
      alias_command="alias $pattern_name='fabric --pattern $pattern_name'"
      eval "$alias_command"
  done
fi

yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

alias vi="nvim"
alias vim="nvim"
alias wallpaper="${HOME}/.local/bin/change_wallpaper.sh"
alias gts='gt status'
alias gtm='gt modify'
alias m='make'
