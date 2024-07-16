#!/bin/sh

set -e

PACKPATH="$XDG_DATA_HOME/nvim/site/pack/develop/start"

[ -d "$PACKPATH" ] || mkdir -p "$PACKPATH"

ln -vs "$PWD" "$PACKPATH"
