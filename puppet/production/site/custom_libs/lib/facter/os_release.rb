# frozen_string_literal: true

Facter.add(:os_release) do
  confine kernel: 'Linux'

  setcode do
    file_path = '/etc/os-release'
    if File.exist?(file_path)
      os_release_hash = {}
      File.open(file_path, 'r') do |file|
        file.each_line do |line|
          next if line.nil? || line.strip.length.eql?(0)

          line_data = line.split('=')
          key = line_data[0].downcase
          value = line_data[1].strip.gsub(/(^")|("$)/, '')
          os_release_hash[key] = value
        end
      end
      os_release_hash
    end
  end
end
