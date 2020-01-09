# Settings common to all *nix boxes
#
# @param [Stdlib::Unixpath] homedir
#   The fully qualified path to my home directory
#
class profile::nix (
  Stdlib::Unixpath $homedir = lookup('homedir'),
) {
  $uid = find_owner($homedir)
  $gid = find_group($homedir)
  $user = homedir_to_user($homedir)

  file {
    default:
      ensure => file,
      owner  => $uid,
      group  => $gid,
    ;
    "${homedir}/.vim":
      ensure => directory,
    ;
    "${homedir}/.vim/bundle":
      ensure => directory,
    ;
    "${homedir}/.vimrc":
      content => epp('profile/vimrc.epp', {}),
    ;
    "${homedir}/.zshrc":
      content => epp('profile/zshrc.epp', {}),
    ;
    "${homedir}/repos":
      ensure => directory,
    ;
    "${homedir}/repos/customized-oh-my-zsh":
      ensure => directory,
    ;
  }

  exec { 'update-fonts':
    command     => "${homedir}/repos/powerline-fonts/install.sh",
    cwd         => "${homedir}/repos/powerline-fonts",
    logoutput   => true,
    environment => "HOME=${homedir}",
    refreshonly => true,
  }

  vcsrepo {
    default:
      ensure   => latest,
      user     => $user,
      owner    => $uid,
      group    => $gid,
      provider => 'git',
    ;
    "${homedir}/.oh-my-zsh":
      ensure => present,
      source => 'https://github.com/robbyrussell/oh-my-zsh.git',
    ;
    "${homedir}/.vim/bundle/Vundle.vim":
      source  => 'https://github.com/VundleVim/Vundle.vim.git',
      require => File["${homedir}/.vim/bundle"],
    ;
    "${homedir}/repos/customized-oh-my-zsh/themes":
      source  => 'https://github.com/genebean/my-oh-zsh-themes.git',
      require => File["${homedir}/repos/customized-oh-my-zsh"],
    ;
    "${homedir}/repos/powerline-fonts":
      source  => 'https://github.com/powerline/fonts.git',
      require => File["${homedir}/repos"],
      notify  => Exec['update-fonts'],
    ;
  }
}
