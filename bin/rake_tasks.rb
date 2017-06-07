desc 'Run dots'
task :dots do
  ruby 'bin/dots.rb'
end

# rubocop:disable Metrics/BlockLength
namespace 'dots' do
  cmd = TTY::Command.new

  desc 'Run r10k'
  task :run_r10k do
    command = 'bundle exec r10k puppetfile install \
      --puppetfile ~/.dotfiles/puppet/production/Puppetfile -v'
    cmd.run(command)
  end

  desc 'Run Puppet'
  task :run_puppet do
    command = 'bundle exec puppet apply \
      --environmentpath ~/.dotfiles/puppet \
      ~/.dotfiles/puppet/production/manifests/site.pp'
    cmd.run(command)
  end

  desc 'Run Puppet (noop)'
  task :run_puppet_noop do
    command = 'bundle exec puppet apply \
      --environmentpath ~/.dotfiles/puppet \
      ~/.dotfiles/puppet/production/manifests/site.pp --noop'
    cmd.run(command)
  end

  desc 'Install Vundle Plugins'
  task :vim_plugins do
    # running this command from bundler refuses to work
    command = 'vim +PluginInstall! +qall'
    puts "Run '#{command}' to get your Vundle plugins installed and/or updated"
  end
end
# rubocop:enable Metrics/BlockLength
