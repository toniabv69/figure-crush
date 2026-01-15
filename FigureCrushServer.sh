#!/bin/sh
printf '\033c\033]0;%s\a' Figure Crush
base_path="$(dirname "$(realpath "$0")")"
"$base_path/FigureCrushServer.x86_64" "$@"
