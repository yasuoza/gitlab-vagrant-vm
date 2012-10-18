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
  not necessary if you are using Windows.
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
