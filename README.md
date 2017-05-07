# dots

My dot files and a tool to deploy them to various OS's

## The Plan

* files in [link/](link) get symlinked to `~/.{filename}`
* files in [copy/](copy) get copied to `~/.{filename}`
  * this process should default to not clobbering existing files
* [bin/dots.rb](bin/dots.rb) is what users will interact with
  * it should bootstrap based on the OS it is being run on
  * it should run Puppet and associated tools such as r10k via bundler
  * it should not utilize Git submodules; it should instead use [vcsrepo](https://forge.puppet.com/puppetlabs/vcsrepo)
    * the destination of each repo may well need to be added to the parent's `.gitignore`
  * it should configure [iTerm2](https://www.iterm2.com/) on Mac
  * it should configure [Atom](https://atom.io/) on all platforms
  * it should offer a choice to skip steps related to GUI programs
  * it should permit host-specific settings / options
    * this will likely be done via entries in a hiera node file
* create a Docker image with all tools preinstaleld and set to mount the current user's home directory as a volume.
  * use [gosu](https://github.com/tianon/gosu) so ownership is correct.
    * this may not work on Windows...

### Notes thus far

1. Install Homebrew
2. Install ruby >= 2.0 (testing with 2.4.1)
3. Install bundler
4. Install cmake and pkg-config

```bash
git clone git@github.com:genebean/dots.git ~/.dotfiles
cd ~/.dotfiles
bundle install
bundle exec r10k puppetfile install --moduledir vendor/puppet_modules --puppetfile puppet/Puppetfile -v
```
