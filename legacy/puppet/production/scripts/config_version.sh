#!/bin/bash

/usr/bin/git --version > /dev/null 2>&1 &&
/usr/bin/git --git-dir $1/../.git rev-parse HEAD ||
date +%s
