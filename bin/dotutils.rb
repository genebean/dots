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

def rename_file(source, destination)
  puts "#{destination} exists, renaming to #{destination}.predots"
  File.rename(destination, "#{destination}.predots")
  puts "Linking #{destination} to #{source}"
  File.symlink(source, destination)
end

def link_file(source, destination)
  if File.exist?(destination) && File.symlink?(destination)
    existing_symlink(source, destination)
  elsif File.exist?(destination)
    # this catches anything that is not a symlink
    rename_file(source, destination)
  else
    puts "Linking #{destination} to #{source}"
    File.symlink(source, destination)
  end
end
