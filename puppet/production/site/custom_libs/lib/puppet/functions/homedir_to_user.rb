# frozen_string_literal: true

Puppet::Functions.create_function(:homedir_to_user) do
  dispatch :homedir_to_user do
    param 'String', :some_path
    return_type 'String'
  end

  def homedir_to_user(some_path)
    some_path.split('/')[-1]
  end
end
