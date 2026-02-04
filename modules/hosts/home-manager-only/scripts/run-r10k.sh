#!/usr/bin/env bash

sudo /home/gene/.nix-profile/bin/r10k puppetfile install \
--puppetfile=/home/gene/repos/dots/Puppetfile  \
--moduledir=/etc/puppetlabs/code/environments/production/modules
