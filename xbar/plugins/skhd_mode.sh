#!/usr/bin/env bash

# <xbar.title>SKHD Mode</xbar.title>
# <xbar.dependencies>bash</xbar.dependencies>

MODE="$(cat /tmp/skhd_mode)"
printf "⌨️ $MODE"
