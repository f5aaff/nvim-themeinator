#!/bin/bash


TEST_FILES="$(ls $HOME/.config/nvim/colors/testing/)"


for FILE in $TEST_FILES; do
    cp ~/.config/nvim/colors/testing/$FILE ~/.config/nvim/colors/"$FILE"_TEST.vim
done
