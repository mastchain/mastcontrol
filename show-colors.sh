#!/bin/bash

printf '\n%-38s %-14s %-14s\n' "Color" "Dark bg" "Light bg"
printf '%-38s %-14s %-14s\n' "-----" "-------" "--------"

show() {
  local name="$1" code="$2" dark="$3" light="$4"
  printf "\033[${code}%-38s\033[0m %-14s %-14s\n" "$name  (\\033[${code})" "$dark" "$light"
}

echo ""
echo "--- Normal ---"
show "Red"            "0;31m"  "ok"       "ok"
show "Green"          "0;32m"  "ok"       "ok"
show "Yellow"         "0;33m"  "ok"       "dark, ok"
show "Blue"           "0;34m"  "dark"     "ok"
show "Magenta"        "0;35m"  "ok"       "ok"
show "Cyan"           "0;36m"  "ok"       "ok"
show "White"          "0;37m"  "ok"       "invisible"
show "Dark gray"      "0;90m"  "dark"     "ok"

echo ""
echo "--- Bold ---"
show "Bold Red"       "1;31m"  "ok"       "ok"
show "Bold Green"     "1;32m"  "ok"       "ok"
show "Bold Yellow"    "1;33m"  "ok"       "ok"
show "Bold Blue"      "1;34m"  "dark"     "ok"
show "Bold Magenta"   "1;35m"  "ok"       "ok"
show "Bold Cyan"      "1;36m"  "ok"       "ok"
show "Bold White"     "1;37m"  "ok"       "invisible"

echo ""
echo "--- Bright ---"
show "Bright Red"     "0;91m"  "ok"       "ok"
show "Bright Green"   "0;92m"  "ok"       "ok"
show "Bright Yellow"  "0;93m"  "ok"       "light"
show "Bright Blue"    "0;94m"  "ok"       "ok"
show "Bright Magenta" "0;95m"  "ok"       "ok"
show "Bright Cyan"    "0;96m"  "ok"       "light"
echo ""
