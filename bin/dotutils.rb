# frozen_string_literal: true

def existing_symlink(source, destination)
  return if File.readlink(destination).eql?(source)

  # rubocop:disable Metrics/LineLength
  if @prompt.yes?("#{destination} currently points to #{File.readlink(destination)}, do you want point it at #{source}?")
    File.unlink(destination)
    puts "Linking #{destination} to #{source}"
    File.symlink(source, destination)
    puts 'link replaced'
  else
    puts "#{destination} is unchanged"
  end
  # rubocop:enable Metrics/LineLength
end

# rubocop:disable Metrics/MethodLength
def rename_file(source, destination, action)
  puts "#{destination} exists, renaming to #{destination}.predots"
  File.rename(destination, "#{destination}.predots")
  if action.eql?('link')
    puts "Linking #{destination} to #{source}"
    File.symlink(source, destination)
  elsif action.eql?('copy')
    puts "Copying #{destination} to #{source}"
    FileUtils.cp_r(source, destination)
  else
    raise ArgumentError, "'#{action}' is not a valid action", backtrace
  end
end
# rubocop:enable Metrics/MethodLength

def copy_file(source, destination)
  if File.exist?(destination)
    if @prompt.yes?("#{destination} exists, do you want to replace it?")
      rename_file(source, destination, 'copy')
    else
      puts "#{destination} is unchanged"
    end
  else
    FileUtils.cp_r(source, destination)
  end
end

def link_file(source, destination)
  if File.exist?(destination) && File.symlink?(destination)
    existing_symlink(source, destination)
  elsif File.exist?(destination)
    # this catches anything that is not a symlink
    rename_file(source, destination, 'link')
  else
    puts "Linking #{destination} to #{source}"
    File.symlink(source, destination)
  end
end

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def mac_vers
  stdout, _stderr, _status = Open3.capture3('sw_vers -productVersion')
  if Integer(stdout.strip.split('.')[0]) == 10
    if Integer(stdout.strip.split('.')[1]) >= 12
      puts "It seems you are on macOS #{stdout.strip}"
    else
      puts "It seems you are on OX X #{stdout.strip}"
    end

  elsif Integer(stdout.strip.split('.')[0]) < 10
    puts "Wow... you're sure running an old os (#{stdout.strip} to be exact)"
  else
    abort("It seems you are on a Mac but I don't know what to do on \
      v#{stdout.strip}")
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
