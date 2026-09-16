#!/usr/bin/env bash

repomix --style markdown \
  --output-show-line-numbers \
  --output "./.repomix/context.md" \
  --split-output=1mb \
  --ignore "**/*.png,**/*.env,**/node_modules/**, **/.repomix/**"