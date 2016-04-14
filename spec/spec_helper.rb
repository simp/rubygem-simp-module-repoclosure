require 'rspec'
require 'simp/module/repoclosure/version'
require 'simp/module/repoclosure'

# return absolute path to mock module directory
# if optional 'file' argument ins present, return path to file iwthin module
def path_to_mock_module(name,file=nil)
  path = File.expand_path("files/modules/#{name}", File.dirname(__FILE__))
  raise "dir Path not found: '#{path}'" unless File.directory? path

  if file
    path = File.expand_path(file,path)
    raise "file Path not found: '#{path}'" unless File.file? path
  end

  path
end

RSpec.configure do |config|
#  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
