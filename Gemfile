# frozen_string_literal: true

# vim:ft=ruby
source 'https://rubygems.org'

# rubocop:disable Style/ConditionalAssignment
if ENV.key?('PUPPET_VERSION')
  puppetversion = ENV['PUPPET_VERSION'].to_s
else
  puppetversion = ['>= 7', '< 8']
end
# rubocop:enable Style/ConditionalAssignment

group :production do
  gem 'os',     '~> 1.1'
  gem 'puppet', puppetversion
  gem 'r10k',   '~> 3.15'
  gem 'rugged', '~> 1.0'
  gem 'xmlrpc', '~> 0.3.0' if RUBY_VERSION >= '2.3'
end

group :development, :unit_tests do
  gem 'json',                                             '>= 2.0.2'
  gem 'metadata-json-lint',                               '~> 3.0'
  gem 'puppetlabs_spec_helper',                           '~> 4.0'
  gem 'rspec-puppet',                                     '~> 2.6'
  gem 'rubocop',                                          '~> 1.30'
  gem 'tty-command',                                      '~> 0.6'
  gem 'tty-file',                                         '~> 0.9'
  gem 'tty-prompt',                                       '~> 0.21'
  gem 'yamllint',                                         '~> 0.0.9'

  # puppet-lint and plugins
  gem 'puppet-lint',                                      '~> 2.3'
  gem 'puppet-lint-absolute_classname-check',             '~> 3.0'
  gem 'puppet-lint-absolute_template_path',               '~> 1.0'
  gem 'puppet-lint-empty_string-check',                   '~> 0.2'
  gem 'puppet-lint-leading_zero-check',                   '~> 0.1'
  gem 'puppet-lint-resource_reference_syntax',            '~> 1.1'
  gem 'puppet-lint-spaceship_operator_without_tag-check', '~> 0.1'
  gem 'puppet-lint-trailing_newline-check',               '~> 1.1'
  gem 'puppet-lint-undef_in_function-check',              '~> 0.2'
  gem 'puppet-lint-unquoted_string-check',                '~> 2.1'
  gem 'puppet-lint-variable_contains_upcase',             '~> 1.2'
end
