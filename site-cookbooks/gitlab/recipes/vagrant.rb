# Include cookbook dependencies
%w{ gitlab::gitlab_shell build-essential
    readline openssh xml zlib python::package python::pip
    redisio::install redisio::enable }.each do |requirement|
  include_recipe requirement
end

# symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
link "/usr/bin/redis-cli" do
  to "/usr/local/bin/redis-cli"
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end

# Install pygments from pip
python_pip "pygments" do
  action :install
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Generate and deploy ssh public/private keys
Gem.clear_paths

# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source "ssh_config.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :trust_local_sshkeys => node['gitlab']['trust_local_sshkeys']
  )
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['gitlab_url']
  reference node['gitlab']['gitlab_branch']
  action :checkout
  user 'root'
end

# Create tmp/repositories/
#
# Uses host user/group id to workaround Vagrant's inability to set the NFS
# share on the virtual machine to the vagrant user.
directory "#{node['gitlab']['app_home']}/tmp/repositories" do
  owner node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode "0755"
  recursive true
  action :create
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  user node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :https_boolean => node['gitlab']['https'],
    :git_user => node['gitlab']['git_user'],
    :git_home => node['gitlab']['git_home']
  )
end

# Use mysql as our database
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml'
  user node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode 0644
end

# Database information
mysql_connexion = { :host     => 'localhost',
                    :username => 'root',
                    :password => node['mysql']['server_root_password'] }

postgresql_connexion = { :host     => 'localhost',
                         :username => 'postgres',
                         :password => node['postgresql']['password']['postgres'] }

# Create mysql user vagrant
mysql_database_user 'vagrant' do
  connection mysql_connexion
  password 'vagrant'
  action :create
end

postgresql_database_user 'vagrant' do
  connection postgresql_connexion
  password 'vagrant'
  action :create
end

# Create databases and users
%w{ gitlabhq_production gitlabhq_development gitlabhq_test }.each do |db|
  mysql_database "#{db}" do
    connection mysql_connexion
    action :create
  end

  postgresql_database "#{db}" do
    connection postgresql_connexion
    action :create
  end

  # Undocumented: see http://tickets.opscode.com/browse/COOK-850
  postgresql_database_user 'vagrant' do
    connection postgresql_connexion
    database_name db
    password 'vagrant'
    action :grant
  end
end

# Grant all privelages on all databases/tables from localhost to vagrant
mysql_database_user 'vagrant' do
  connection mysql_connexion
  password 'vagrant'
  action :grant
end


# Render Xvfb start service
template "/etc/init.d/xvfb" do
  owner "root"
  group "root"
  mode 0755
  source "xvfb.sh.erb"
end

# Append default Display (99.0) in bashrc
template "/etc/bash.bashrc" do
  owner "root"
  group "root"
  mode 0755
  source "bash.bashrc"
end

# Create directory for bundle options.
directory "#{node['gitlab']['home']}/.bundle" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0755
end

# Add default options for bundler (fixes bug with charlock_holmes)
template "#{node['gitlab']['home']}/.bundle/options" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  source "bundle_options"
end

# Xvfb start
service "xvfb" do
  action :start
end

# Install Gems with bundle install
# `execute` doesn't use the user environment and so this is a work around to do
# as if it was vagrant and not root.
# http://tickets.opscode.com/browse/CHEF-2288?page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#issue-tabs
execute "gitlab-bundle-install" do
  command "su -l -c 'cd #{node['gitlab']['app_home']} && bundle install' vagrant"
  cwd node['gitlab']['app_home']
  user 'root'
end

%w{ development test }.each do |env|
  # Setup database
  execute "gitlab-#{env}-setup" do
    command "su -l -c 'cd #{node['gitlab']['app_home']} && bundle exec rake db:setup RAILS_ENV=#{env}' vagrant"
    cwd node['gitlab']['app_home']
    user 'root'
    not_if { File.exists?("#{node['gitlab']['home']}/.vagrant_seed") }
  end

  # Seed database
  execute "gitlab-#{env}-seed" do
    command "su -l -c 'cd #{node['gitlab']['app_home']} && bundle exec rake db:seed_fu RAILS_ENV=#{env}' vagrant"
    cwd node['gitlab']['app_home']
    user 'root'
    not_if { File.exists?("#{node['gitlab']['home']}/.vagrant_seed") }
  end
end

# Create this file to avoid seeding again
file "#{node['gitlab']['home']}/.vagrant_seed" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  action :create
end
