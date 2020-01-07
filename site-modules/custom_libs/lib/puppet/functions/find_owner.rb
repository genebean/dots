# frozen_string_literal: true

Puppet::Functions.create_function(:find_owner) do
  dispatch :find_owner do
    param 'String', :some_path
    return_type 'String'
  end

  def find_owner(some_path)
    File.stat(some_path).uid.to_s
  end
end
