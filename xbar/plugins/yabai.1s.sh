#!/usr/bin/env bash

# <xbar.title>Yabai focus</xbar.title>
# <xbar.image>https://i.imgur.com/B6VAsDg.png</xbar.image>
# <xbar.dependencies>bash</xbar.dependencies>

export PATH=/opt/homebrew/bin:${PATH}

windowFocused=$(yabai -m query --windows | jq 'map(select(."has-focus" == true))' | jq '.[0].app')
windowFocused="${windowFocused//\"/}"
space=$(yabai -m query --spaces --space | jq ".index")
display=$(yabai -m query --spaces --space | jq ".display")

if [[ "$windowFocused" != "null" ]]; then
  echo "👁️[$display-$space]$windowFocused"
else
  # no window active
  echo "👁️[$display-$space]"
fi
