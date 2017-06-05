require 'open3'
require 'os'
require 'tty-command'
require 'tty-file'
require 'tty-prompt'
require_relative 'dotutils.rb'

cmd     = TTY::Command.new
@prompt = TTY::Prompt.new(help_color: :magenta)

@home       = File.expand_path('~')
@dotroot    = File.dirname(File.dirname(File.expand_path($PROGRAM_NAME)))
@excludes   = %w[mac nix ssh]
@files_copy = Dir.glob("#{@dotroot}/copy/*")
@files_link = Dir.glob("#{@dotroot}/link/*")
@ssh_link   = Dir.glob("#{@dotroot}/link/ssh/*")

if OS.posix?
  @files_copy.concat Dir.glob("#{@dotroot}/copy/nix/*")
  @files_link.concat Dir.glob("#{@dotroot}/link/nix/*")
end

if OS.windows?
  puts 'It seems you are on Windows'

elsif OS.mac?
  mac_vers

  @files_copy.concat Dir.glob("#{@dotroot}/copy/mac/*")
  @files_link.concat Dir.glob("#{@dotroot}/link/mac/*")

elsif OS.liux?
  puts 'It seems you are on Linux'

else
  abort("I'm not sure what to do with this OS...") unless OS.posix?
end

task = @prompt.select('What would you like to do?', %w[copy link install])
case task
when 'copy'
  if @prompt.yes?('Are you sure you want to copy these files?')
    @files_copy.each do |file|
      unless @excludes.include?(File.basename(file))
        puts "Copying #{file} to #{@home}/.#{File.basename(file)}"
        copy_file(file, "#{@home}/.#{File.basename(file)}")
      end
    end
  else
    puts 'not copying'
  end

when 'link'
  if @prompt.yes?('Are you sure you want to link your dot files?')
    @files_link.each do |file|
      unless @excludes.include?(File.basename(file))
        # puts "Linking #{@home}/.#{File.basename(file)} to #{file}"
        link_file(file, "#{@home}/.#{File.basename(file)}")
      end
    end

    # rubocop:disable Style/NumericLiteralPrefix
    Dir.mkdir("#{@home}/.ssh", 0700) unless File.directory?("#{@home}/.ssh")
    # rubocop:enable Style/NumericLiteralPrefix
    @ssh_link.each do |file|
      link_file(file, "#{@home}/.ssh/#{File.basename(file)}")
    end
  else
    puts 'not linking'
  end

when 'install'
  if @prompt.yes?('Are you sure you want to install your base packages?')
    cmd.run('bundle exec rake dots:run_puppet')
    cmd.run('bundle exec rake dots:vim_plugins')
  end
end
