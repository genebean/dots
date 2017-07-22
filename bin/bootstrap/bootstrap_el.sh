#!/bin/bash

if [[ $1 == 'now' ]]; then
  # Install dot's dependencies
  yum install -y centos-release-scl-rh.noarch
  yum install rh-ruby24 rh-ruby24-ruby-devel rh-ruby24-rubygem-bundler rh-ruby24-rubygem-rake cmake

  # Make dot usable
  cd ~/.dotfiles
  /bin/scl enable rh-ruby24 'bundle install'

  # Install Puppet modules
  /bin/scl enable rh-ruby24 'bundle exec rake dots:run_r10k'

  # Display tasks that can be run
  echo 'These are the task that can now be executed:'
  /bin/scl enable rh-ruby24 'bundle exec rake -T' |grep --color=never 'rake dots'
fi
