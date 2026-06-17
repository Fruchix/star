#!/usr/bin/env bash

git_branch="$(git branch --show-current)"

if [[ -z "$git_branch" ]]; then
  echo "Error: could not determine git branch." >&2
  exit 1
fi

clean_git_branch=$(echo "$git_branch" | tr --complement --delete '[:alnum:]' | tr '[:upper:]' '[:lower:]')

echo "Running Docker image for branch '$git_branch'."

docker run --rm -it "star-ubuntu-${clean_git_branch}"
