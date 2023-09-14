# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'tty-command'
require 'yamllint/rake_task'
require_relative 'bin/rake_tasks'

exclude_paths = [
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*'
]

# https://docs.rubocop.org/rubocop/0.86/integration_with_other_tools.html#rake-integration
RuboCop::RakeTask.new

PuppetLint::RakeTask.new :lint do |config|
  config.fail_on_warnings = true
  config.ignore_paths     = exclude_paths
end

PuppetSyntax.exclude_paths = exclude_paths

desc 'Validate manifests, templates, and ruby files'
task :validate do
  Dir['puppet/manifests/**/*.pp',
      'puppet/site/*/manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['bin/**/*.rb',
      'spec/**/*.rb'].each do |ruby_file|
    # rubocop:disable Style/RegexpLiteral
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
    # rubocop:enable Style/RegexpLiteral
  end
  Dir['puppet/site/*/templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

YamlLint::RakeTask.new do |yamllint|
  yamllint.paths = %w[
    .*.yaml
    .*.yml
    *.yaml
    *.yml
    copy/**/*.yml
    link/**/*.yml
    puppet/hieradata/**/*.yml
    puppet/hieradata/**/*.yaml
  ]
end

task :tests do
  Rake::Task[:lint].invoke
  Rake::Task[:yamllint].invoke
  Rake::Task[:validate].invoke
  Rake::Task[:rubocop].invoke
  Rake::Task[:spec].invoke
end
