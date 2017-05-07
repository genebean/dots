require 'open3'
require 'os'

if OS.mac?
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
elsif OS.liux?
  puts 'It seems you are on Linux'
elsif OS.windows?
  puts 'It seems you are on Windows'
else
  abort("I'm not sure what to do with this OS...")
end
