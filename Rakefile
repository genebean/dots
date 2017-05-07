require 'rubocop/rake_task'
require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'yamllint/rake_task'

exclude_paths = [
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*'
]

RuboCop::RakeTask.new
RuboCop::RakeTask.new(:rubocop) do |task|
  # task.patterns = ['lib/**/*.rb']
  # only show the files with failures
  # task.formatters = ['files']
  # don't abort rake on failure
  # task.fail_on_error = false
end

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.ignore_paths = exclude_paths
PuppetLint.configuration.log_format =
  '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'

PuppetSyntax.exclude_paths = exclude_paths

desc 'Validate manifests, templates, and ruby files'
task :validate do
  Dir['puppet/manifests/**/*.pp',
      'puppet/site/*/manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['bin/**/*.rb',
      'spec/**/*.rb'].each do |ruby_file|
    # rubocop:disable RegexpLiteral
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
    # rubocop:enable RegexpLiteral
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
