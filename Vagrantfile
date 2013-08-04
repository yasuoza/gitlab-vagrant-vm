# You can ask for more memory and cores when creating your Vagrant machine:
# GITLAB_VAGRANT_MEMORY=1536 GITLAB_VAGRANT_CORES=2 vagrant up
MEMORY = ENV['GITLAB_VAGRANT_MEMORY'] || '1024'
CORES = ENV['GITLAB_VAGRANT_CORES'] || '1'

Vagrant::Config.run do |config|
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.network :hostonly, '192.168.3.14'

  # Default user/group id for vagrant in precise32
  host_user_id = 1000
  host_group_id = 1000

  if RUBY_PLATFORM =~ /linux|darwin/
    config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)
    host_user_id = Process.euid
    host_group_id = Process.egid
  end

  # config.vm.provision :shell, :inline => "gem install chef --version 11.6.0 --no-rdoc --no-ri --conservative"

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ['cookbooks', 'site-cookbooks']

    chef.add_recipe('zsh')

    chef.add_recipe('ruby_build')
    chef.add_recipe('rbenv::vagrant')
    chef.add_recipe('rbenv::user')

    chef.add_recipe('mysql::server')
    chef.add_recipe('mysql::ruby')

    chef.add_recipe('postgresql::server')
    chef.add_recipe('postgresql::ruby')

    chef.add_recipe('database::mysql')

    chef.add_recipe('phantomjs')

    # This is where all the magic happens.
    # see site-cookbooks/gitlab/
    chef.add_recipe('gitlab::vagrant')

    chef.json = {
      :rbenv => {
        :user_installs => [
          { :user         => 'vagrant',
            :rubies       => ['2.0.0-p247', '1.9.3-p448'],
            :global       => '2.0.0-p247',
            :gems         => {
              '2.0.0-p247' => [
                {:name    => 'bundler'}
              ],
              '1.9.3-p448' => [
                {:name    => 'bundler'}
              ]
            }
        }
        ],
        :vagrant => {
          :system_chef_solo => '/opt/vagrant_ruby/bin/chef-solo'
        },
        :global_gems => [{ :name => 'bundler'}],
        :branch => 'none',
        :version => '1.17.10'
      },
      :phantomjs => {
        :version => '1.8.1'
      },
      :redisio => {
        :version => '2.6.14'
      },
      :mysql => {
        :server_root_password => "nonrandompasswordsaregreattoo",
        :server_repl_password => "nonrandompasswordsaregreattoo",
        :server_debian_password => "nonrandompasswordsaregreattoo"
      },
      :gitlab => {
        :host_user_id => host_user_id,
        :host_group_id => host_group_id
      }
    }
  end
end

Vagrant.configure("2") do |config|
    config.vm.provider :vmware_fusion do |v, override|
        override.vm.box = "precise64"
        override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
        v.vmx["memsize"] = MEMORY
        v.vmx["numvcpus"] = CORES
    end

    config.vm.provider :virtualbox do |v, override|
        v.customize ["modifyvm", :id, "--memory", MEMORY.to_i]
        v.customize ["modifyvm", :id, "--cpus", CORES.to_i]
    end
end
