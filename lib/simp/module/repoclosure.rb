require 'simp/module/repoclosure/version'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'
require 'r10k/puppetfile'

module Simp
  module Module
    class Repoclosure
      def initialize( module_dir )
        metadata_json = File.join( module_dir, 'metadata.json' )
        @metadata = Simp::Module::Metadata.new(metadata_json)
      end

      def do
        Dir.mktmpdir('fakeforge_mut_dir_') do |mut_dir|
          Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
            Dir.mktmpdir('fakeforge_pupmod_install_dir_') do |pupmod_install_dir|
              puppetfile = @metadata.to_puppetfile
              File.open( File.join( mut_dir, 'Puppetfile' ), 'w' ){|f| f.puts result }
              FileUtils.chdir mut_dir
              `r10k puppetfile checkout`
            end
          end
        end
      end

    end
  end
end
