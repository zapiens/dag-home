#!/bin/bash

function set_link() {
    [ -e ~/"$1" ] || ln -s $(pwd)/"$1" ~/"$1"
 }

set_link .bashrc
set_link .emacs
set_link .gitconfig
