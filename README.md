Gitlab-Vagrant-VM
=================

Description
-----------

Setup a dev environment for Gitlab.

The final product contain all databases set up, working tests and all gems
installed.

Requirements
------------

* [VirtualBox](https://www.virtualbox.org)
* [Vagrant](http://vagrantup.com)
* the NFS packages. Already there if you are using Mac OS, and
  not necessary if you are using Windows. On Linux:

```bash
$ sudo apt-get install nfs-kernel-server nfs-common portmap
```

* some patience :)

Installation
------------

Clone the repository:

```bash
$ git clone https://github.com/gitlabhq/gitlab-vagrant-vm
$ cd gitlab-vagrant-vm
```

And install gems and chef's necessary packages:

```bash
$ bundle install
$ bundle exec librarian-chef install
```

Finally, you should be able to use:

```bash
$ vagrant up
```

You'll be asked for your password to set up NFS shares.

Once everything is done you can log into the virtual machine to run tests:

```bash
$ vagrant ssh
$ cd /vagrant/gitlabhq/
$ bundle exec rake gitlab:test
```

You should also configure your own remote since by default it's going to grab
gitlab's master branch.

```bash
$ git remote add mine git://github.com/me/gitlabhq.git
$ # or if you prefer set up your origin as your own repository
$ git remote set-url origin git://github.com/me/gitlabhq.git
```

Virtual Machine Management
--------------------------

When done just log out with `^D` and suspend the virtual machine

```bash
$ vagrant suspend
```

then, resume to hack again

```bash
$ vagrant resume
```

Run

```bash
$ vagrant halt
```

to shutdown the virtual machine, and

```bash
$ vagrant up
```

to boot it again.

You can find out the state of a virtual machine anytime by invoking

```bash
$ vagrant status
```

Finally, to completely wipe the virtual machine from the disk **destroying all its contents**:

```bash
$ vagrant destroy # DANGER: all is gone
```

Information
-----------

* Virtual Machine IP: 192.168.3.14
* User/password: vagrant/vagrant
* MySQL user/password: vagrant/Vagrant
* MySQL root password: nonrandompasswordsaregreattoo
* Xvfb is used as a service and it should be already running, but in case you
  need to restart it manually:

```bash
$ sudo /etc/init.d/xvfb stop
$ sudo /etc/init.d/xvfb start
```

Updating
---------------

The gitlabhq version is _not_ updated when you rebuild your virtual machine with the following command:

```bash
$ vagrant destroy && vagrant up
```

You must update it yourself by going to the gitlabhq subdirectory in the gitlab-vagrant-vm repo and pulling the latest changes:

```bash
$ cd gitlabhq && git pull --ff origin master
```

A bit of background on why this is needed. When you run 'vagrant up' there is a [checkout action in the recipe](https://github.com/gitlabhq/gitlab-vagrant-vm/blob/master/site-cookbooks/gitlab/recipes/vagrant.rb#L54) that [points to](https://github.com/gitlabhq/gitlab-vagrant-vm/blob/master/site-cookbooks/gitlab/attributes/vagrant.rb#L10) the [gitlabhq repo](https://github.com/gitlabhq/gitlabhq). You won't see any difference when running 'git status' in the gitlab-vagrant-vm repo because gitlabhq/ is in the [.gitignore](https://github.com/gitlabhq/gitlab-vagrant-vm/blob/master/.gitignore). You can update the gitlabhq repo yourself or remove the gitlabhq directory so the repo is checked out again.


Troubleshooting
---------------

### Error executing action `install` on resource 'rvm_global_gem[bundler]' in chef when booting VM
Stacktrace of this failure can be found in this [gist](https://gist.github.com/3a8410c08c654a95c826) .
This is caused by an [error in rvm](https://github.com/wayneeseguin/rvm/issues/1266) which causes chef-rvm cookbook to fail.
This problem should be fixed with rvm version 1.16.18.
Temporary solution for this is provided in [this commit](https://github.com/gpsnail/chef-rvm/commit/203a785bf217bf90115c2a3f8a479225b27d5483).
In cookbooks/rvm/libraries/chef_rvm_ruby_helpers.rb change the line 41 to

```
@installed_rubies = @rvm_env.list_strings.reject {|e| e == 'nil'}
```
and run vagrant up again to complete the installation.