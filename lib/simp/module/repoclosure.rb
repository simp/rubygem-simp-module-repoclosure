require 'simp/module/repoclosure/version'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'r10k/puppetfile'

module Simp
  module Module
    class Repoclosure
      attr_reader :mut_dir, :tut_dir, :modpath_dir
      def initialize( metadata_json, options = {} )
        @metadata = JSON.parse(File.read(metadata_json))
        @xref_fixtures = true

        fixtures_file = File.join(File.dirname(metadata_json),'.fixtures.yml')
        @fixtures = nil
        if @xref_fixtures && (File.file? fixtures_file)
          @fixtures = YAML.load_file fixtures_file
        end
      end

      def do
        Dir.mktmpdir('fakeforge_mut_dir_') do |mut_dir|
          Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
            Dir.mktmpdir('fakeforge_pupmod_install_dir_') do |pupmod_install_dir|
              puppetfile = puppetfile_from_metadata
              File.open( File.join( mut_dir, 'Puppetfile' ), 'w' ){|f| f.puts result }
            end
          end
        end
      end

      # generate Puppetfile String from metadata.json & .fixtures.yml
      def  puppetfile_from_metadata
       result = ""

       @metadata.fetch('dependencies').each do |dep|
         name    =  dep['name'].sub(/^[^-]+-/,'')
         details = "'#{dep['version_requirement'].match(/(\d+(\.\d){0,2})/)}'"

         # git
         if @xref_fixtures && @fixtures
           fix_repos = @fixtures['fixtures'].fetch('repositories',{})
           if fix_repos.key? name

             _details = fix_repos[name]
             if _details.is_a?(String)
               details = "\n  :git => '#{_details}'"
             elsif (_details.is_a?(Hash) && _details.key?('repo') && _details.key?('ref') )
               details =  "\n  :git => '#{_details['repo']}'"
               details += "\n  :ref => '#{_details['ref']}'"
             else
               fail "ERROR: Unrecognized syntax in .fixtures.yml:\n---\n#{_details}'\n---\n"
             end

           end
         end
         result << "\nmod '#{name}', #{details}"
       end
       result.strip
      end
    end
  end
end
