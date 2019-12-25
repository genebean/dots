# vim:ft=ruby
source 'https://rubygems.org'

# rubocop:disable ConditionalAssignment
if ENV.key?('PUPPET_VERSION')
  puppetversion = ENV['PUPPET_VERSION'].to_s
else
  puppetversion = ['>= 5', '< 6']
end
# rubocop:enable ConditionalAssignment

group :production do
  gem 'os',     '~> 1.0'
  gem 'puppet', puppetversion
  gem 'r10k',   '~> 2.5'
  gem 'rugged', '~> 0.26'
  gem 'xmlrpc', '~> 0.3.0' if RUBY_VERSION >= '2.3'
end

group :development, :unit_tests do
  gem 'json',                                             '>= 2.0.2'
  gem 'metadata-json-lint',                               '~> 2.0'
  gem 'puppetlabs_spec_helper',                           '~> 2.3'
  gem 'rspec-puppet',                                     '~> 2.7'
  gem 'rubocop',                                          '~> 0.50'
  gem 'tty-command',                                      '~> 0.6'
  gem 'tty-file',                                         '~> 0.4'
  gem 'tty-prompt',                                       '~> 0.13'
  gem 'yamllint',                                         '~> 0.0.9'

  # puppet-lint and plugins
  gem 'puppet-lint',                                      '~> 2.3'
  gem 'puppet-lint-absolute_classname-check',             '~> 0.2'
  gem 'puppet-lint-absolute_template_path',               '~> 1.0'
  gem 'puppet-lint-empty_string-check',                   '~> 0.2'
  gem 'puppet-lint-leading_zero-check',                   '~> 0.1'
  gem 'puppet-lint-resource_reference_syntax',            '~> 1.0'
  gem 'puppet-lint-spaceship_operator_without_tag-check', '~> 0.1'
  gem 'puppet-lint-trailing_newline-check',               '~> 1.1'
  gem 'puppet-lint-undef_in_function-check',              '~> 0.2'
  gem 'puppet-lint-unquoted_string-check',                '~> 0.3'
  gem 'puppet-lint-variable_contains_upcase',             '~> 1.2'
end
