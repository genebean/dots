# dots

My dot files and a tool to deploy them, and the programs that use them, to
various OS's. Some additional tools that I consider part of my baseline setup
are also installed and, if possible, configured by dots.

Dots is written in ruby and utilizes bundler to keep all its dependancies
as self-contained as possible. Installation of programs and management of git
repositories is handled by way of the
[Puppet gem](https://rubygems.org/gems/puppet).

Everything about dots assumes you are running it as a normal user, not as root.
Strange and unexpected things could well happen if you run any part of it as
root or via sudo.


## Initial Setup

```bash
git clone git@github.com:genebean/dots.git ~/.dotfiles
cd ~/.dotfiles
bin/bootstrap.sh
This script takes care of getting dots ready to use
Enter the number of the task you want to perform:
1) Mac setup
2) EL setup
3) Quit
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
* `link/mac/`: files in here get symlinked on all Macs
* `link/nix/`: files in here get symlinked on all Posix systems
* `link/ssh/`: these files get symlinked under `~/.ssh/` on all Posix systems
* `puppet/`: this is basically a control repo modified to suite this setup
* `puppet/production/`: items from an environment's branch in a control repo
  * this setup assumes Puppet 4 and Hiera 5. Hiera's config is parsed as part of
    the environment rather than from a global config file.
* `spec/`: unit tests go here
