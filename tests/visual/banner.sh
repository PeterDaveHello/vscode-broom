#!/usr/bin/env bash
set -euo pipefail

# VS Code Banner (Blue -> Cyan)
BANNER_VSCODE_LINES=(
  '██    ██  ██████   ██████   ██████   ██████   ███████'
  '██    ██ ██       ██    ██ ██    ██  ██   ██  ██     '
  '██    ██ ███████  ██       ██    ██  ██   ██  █████  '
  ' ██  ██       ██  ██       ██    ██  ██   ██  ██     '
  '  ████    ██████   ██████   ██████   ██████   ███████'
)

# Broom Art (Angled handle, Wide bristles)
BANNER_BROOM_ICON=(
  '       █'
  '      █ '
  '     █  '
  '   ▄███▄'
  '   ▀▀▀▀▀'
)

BANNER_BROOM_TEXT=(
  '██████   ██████   ██████   ██████   ███    ███'
  '██   ██  ██   ██ ██    ██ ██    ██  ████  ████'
  '██████   ██████  ██    ██ ██    ██  ██ ████ ██'
  '██   ██  ██   ██ ██    ██ ██    ██  ██  ██  ██'
  '██████   ██   ██  ██████   ██████   ██      ██'
)

print_gradient_text() {
  local text="$1"
  local start_r=$2 start_g=$3 start_b=$4
  local end_r=$5 end_g=$6 end_b=$7

  local len=${#text}
  local denom=$((len > 1 ? len - 1 : 1))
  local i char r g b

  for ((i = 0; i < len; i++)); do
    char="${text:$i:1}"
    if [[ "$char" == " " ]]; then
      printf " "
      continue
    fi

    r=$((start_r + (end_r - start_r) * i / denom))
    g=$((start_g + (end_g - start_g) * i / denom))
    b=$((start_b + (end_b - start_b) * i / denom))

    printf "\033[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "$char"
  done
  printf "\033[0m"
}

print_banner() {
  local i j line

  # 1. Print VS Code Banner (Blue -> Cyan)
  local vs_start_r=0 vs_start_g=122 vs_start_b=204
  local vs_end_r=0 vs_end_g=180 vs_end_b=216

  for line in "${BANNER_VSCODE_LINES[@]}"; do
    print_gradient_text "$line" $vs_start_r $vs_start_g $vs_start_b $vs_end_r $vs_end_g $vs_end_b
    printf "\n"
  done
  printf "\n"

  # 2. Print Broom + Text
  # Broom Handle: Brown (139, 69, 19)
  # Broom Bristles: Gold (255, 215, 0)
  # Text: Purple (138, 43, 226) -> Pink (255, 20, 147)

  local text_start_r=138 text_start_g=43 text_start_b=226
  local text_end_r=255 text_end_g=20 text_end_b=147

  for ((i = 0; i < ${#BANNER_BROOM_TEXT[@]}; i++)); do
    # Print Broom part
    local broom_line="${BANNER_BROOM_ICON[$i]}"
    local broom_len=${#broom_line}

    for ((j = 0; j < broom_len; j++)); do
      local char="${broom_line:$j:1}"
      if [[ "$char" == " " ]]; then
        printf " "
        continue
      fi

      if [[ $i -lt 3 ]]; then
        # Handle: Brown
        printf "\033[38;2;139;69;19m%s" "$char"
      else
        # Bristles: Gold
        printf "\033[38;2;255;215;0m%s" "$char"
      fi
    done
    printf "\033[0m   " # Reset and spacer
    print_gradient_text "${BANNER_BROOM_TEXT[$i]}" $text_start_r $text_start_g $text_start_b $text_end_r $text_end_g $text_end_b
    printf "\n"
  done
  printf "\n"

  # 3. Print "VSCODE BROOM" text with gradient
  # Footer: VS Code Blue -> Pink, then broom suffix
  local footer="VSCODE BROOM"
  local footer_suffix=$' \xF0\x9F\xA7\xB9'
  print_gradient_text "$footer" 0 122 204 255 20 147
  printf "\033[38;2;255;20;147m%s\033[0m\n\n" "$footer_suffix"
}

print_banner
