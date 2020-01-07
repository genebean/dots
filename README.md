# dots

[![Build Status](https://travis-ci.com/genebean/dots.svg?branch=master)](https://travis-ci.com/genebean/dots)
[![Dependency Status](https://gemnasium.com/badges/github.com/genebean/dots.svg)](https://gemnasium.com/github.com/genebean/dots)
[![security](https://hakiri.io/github/genebean/dots/master.svg)](https://hakiri.io/github/genebean/dots/master)

My dot files and a tool to deploy them, and the programs that use them, to
various OS's. Some additional tools that I consider part of my baseline setup
are also installed and, if possible, configured by dots.

Dots is written in ruby and utilizes bundler to keep all its dependancies
as self-contained as possible. Installation of programs and management of git
repositories is handled by way of the
[Puppet gem](https://rubygems.org/gems/puppet).

Everything about dots macOS assumes you are running it as a normal user,
not as root. Strange and unexpected things could well happen if you run any part
of it as root or via sudo while on macOS. That said, sudo is required on Debian
due to there not being an equivalent to homebrew as you need sudo to use apt.


## Currently Supported OS's

* macOS
* Linux Mint 18.2


## Initial Setup

```bash
git clone git@github.com:genebean/dots.git ~/.dotfiles
cd ~/.dotfiles
bin/bootstrap.sh
This script takes care of getting dots ready to use
Enter the number of the task you want to perform:
1) Mac setup
2) EL setup
3) Mint setup
4) Quit
Task:
```

After you run the setup for your OS you will want to make sure that
[puppet/production/hieradata/nodes/](puppet/production/hieradata/nodes/)
contains a file matching the hostname of your machine. That file needs to
contain at least the following:

```yaml
---
homedir: '/Users/johndoe'
```

Naturally, you will want to adjust the entry to match the real path to your
home directory. On a Mac this is generally in `/Users/` or `/home/` on Linux.


## Running dots

The primary way to interact with dots is via `bundle exec rake dots`.
This will run an interactive cli program like so:

```
$ bundle exec rake dots
/usr/local/Cellar/ruby/2.4.1_1/bin/ruby bin/dots.rb
It seems you are on macOS 10.12.5
What would you like to do? (Use arrow keys, press Enter to select)
‣ copy
  link
  install
```

If not on macOS then you will need to use sudo for the install step:

```
$ sudo bundle exec rake dots
```

Additional tasks are available in the
dots namespace. You can see all the available tasks via
`bundle exec rake -T`.


## Notes

#### Running Puppet

```bash
# Any of these will work:
bundle exec rake dots:run_puppet
bundle exec rake dots:run_puppet_noop
bundle exec puppet apply --environmentpath ~/.dotfiles/puppet ~/.dotfiles/puppet/production/manifests/site.pp
```

As mentioned above, when not on macOS you will need to prefix bundle with sudo.


#### Installed Homebrew packages

To see what has been installed (not the deps) run `brew leaves`


## Project structure

* `bin/`: this is where the "application" bits live
* `bin/bootstrap`: platform specific helpers called by `bin/bootstrap.sh`
* `copy/`: files directly in this directory are copied to all hosts
* `copy/mac/`: files in here get copied to Macs
* `copy/nix/`: files in here get copied to all Posix systems
* `link/`: files directly in this directory are symlinked on all hosts.
  * all symlinks are prefixed with a dot. Ex: `link/gemrc` becomes `~/.gemrc`
* `link/linux/`: files in here get symlinked on all Linux distros
* `link/mac/`: files in here get symlinked on all Macs
* `link/nix/`: files in here get symlinked on all Posix systems
* `link/ssh/`: these files get symlinked under `~/.ssh/` on all Posix systems
* `puppet/`: this is basically a control repo modified to suit this setup
* `puppet/production/`: items from an environment's branch in a control repo
  * this setup assumes Puppet 4 and Hiera 5. Hiera's config is parsed as part of
    the environment rather than from a global config file.
* `spec/`: unit tests go here


## Adding Packages

To add additional pacakages to be installed and managed by dots you will need to
edit the associated Puppet manifest. Currently, this consists of the following:

```bash
puppet/production/site/profile/manifests/
├── base.pp
├── linux
│   └── debian.pp
├── linux.pp
└── mac.pp
```

On macOS you can easily install packages and casks from homebrew or Python
modules from pip. On Linux Mint you can easily use any package provider
that supports Debian or Ubuntu since all installs are done via sudo. On both
platforms you can also use custom exec's to to work around limitations. For
example, an exec is used on Mint to set the shell to zsh and on both platforms
to install or update the powerline fonts.


## Puppet Customizations

This repo also contains some custom facts and functions under
`puppet/production/site/custom_libs`:

### Facts

* `os_release`: this creates a structured fact out of the contents of
  /etc/os-release on Linux systems. This info is needed on Mint to determine
  what version of Ubuntu it is based on.

### Functions

* `find_group`: returns the owning group's GID as a string for the file or
  folder at a given path
* `find_owner`: returns the owning user's UID as a string for the file or
  folder at a given path
