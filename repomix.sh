#!/usr/bin/env bash

repomix --style xml \
  --output-show-line-numbers \
  --output "./.repomix/context.xml" \
  --split-output=1mb \
  --ignore "**/*.png,**/*.env,**/node_modules/**, **/.repomix/**"