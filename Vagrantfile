# frozen_string_literal: true

Vagrant.configure('2') do |config|
  config.vm.box = 'genebean/centos-7-nocm'
  config.vm.hostname = 'centtest'
  config.vm.provision 'shell', inline: <<-END
    rpm -Uvh https://yum.puppet.com/puppet-tools-release-el-7.noarch.rpm
    yum install -y puppet-bolt
    cd /vagrant
    /usr/local/bin/bolt plan run role::apply_local
  END
end
