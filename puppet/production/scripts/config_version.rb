#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require 'rugged'
rescue LoadError
  t = Time.new
  puts t.to_i
else
  environmentpath = ARGV[0]
  environment     = ARGV[1]

  repo = Rugged::Repository.discover(File.join(environmentpath, environment))
  head = repo.head

  # sha1 hash of the newest commit
  head_sha = head.target_id

  # the commit message associated the newest commit
  # commit = repo.lookup(head_sha)

  # add something to find the remote url

  puts head_sha
end
