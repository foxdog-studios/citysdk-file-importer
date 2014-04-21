#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

cd -- ${0:h}/..
bundle exec ruby main.rb $@

