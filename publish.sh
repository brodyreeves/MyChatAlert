#!/bin/bash

##  argument validation
# make sure correct number of arguments were passed
if [ $# -eq 0 ] || [ $# -gt 1 ]; then
    echo "Usage: publish <tag>"
    exit
fi

# check first argument (tag name) is valid - v#.#.#-retail, v#.#.#-classic, or v#.#.#-bcc
if ! [[ "$1" =~ ^(v[1-9][0-9]{0,2})(\.[0-9]{1,3}){2,3}-(retail|classic|bcc)$ ]]; then
    echo "Invalid tag name"
    exit
fi

## Check tag can be published
echo "Checking for local tag existence"

result=$(git tag -l | grep -cx "$1")

if [ $result -gt 0 ]; then
    echo "Tag already exists locally"
    exit
fi

echo "Checking for remote tag existence"

result=$(curl -s "https://api.github.com/repos/brodyreeves/MyChatAlert/tags" | grep -Po '"name":.*?[^\\]",' | grep -cP "\"$1\"")

if [ $result -gt 0 ]; then
    echo "Tag already exists on remote"
    exit
fi

echo "Tagging with '$1'"

git tag $1

echo "Pushing tag  '$1'"

git push origin $1

echo "Done"
