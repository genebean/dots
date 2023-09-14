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


### Packages to install on Mac's

#### Vundle & Vim

Install via Puppet:

1. link `vimrc`
2. vcsrepo: https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
3. exec `vim +PluginInstall +qall`

#### Powerline

```bash
brew install coreutils python socat tmux
pip install psutil powerline-status
git clone https://github.com/powerline/fonts.git ~/repos/powerline-fonts
cd ~/repos/powerline-fonts
./install.sh
```

##### Thoughts on installing with Puppet:

* [x] install packages using a provider for homebrew
* [x] install packages using the pip provider
* [x] use vcsrepo to clone the fonts
* [x] create a refresh-only exec that runs the install script
* [x] add a notify to the vcsrepo resource that triggers the exec
  * this will also take care of bringing in new fonts or updates
