require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'yamllint/rake_task'

exclude_paths = [
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*'
]

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.ignore_paths = exclude_paths
PuppetLint.configuration.log_format = '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'

PuppetSyntax.exclude_paths = exclude_paths

desc 'Validate manifests, templates, and ruby files'
task :validate do
  Dir['puppet/manifests/**/*.pp', 'puppet/site/*/manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['bin/**/*.rb', 'spec/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file.match? %r{spec\/fixtures}
  end
  Dir['puppet/site/*/templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

task :tests do
  Rake::Task[:lint].invoke
  Rake::Task[:validate].invoke
  Rake::Task[:spec].invoke
end
