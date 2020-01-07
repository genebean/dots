# frozen_string_literal: true

Puppet::Functions.create_function(:find_group) do
  dispatch :find_group do
    param 'String', :some_path
    return_type 'String'
  end

  def find_group(some_path)
    File.stat(some_path).gid.to_s
  end
end
