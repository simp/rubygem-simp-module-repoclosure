require 'simp/module/repoclosure/version'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'

module Simp
  module Module
    class Metadata
      def initialize( metadata_json_path )
        @metadata = JSON.parse(File.read(metadata_json_path))
        @xref_fixtures = true

        fixtures_file = File.join(File.dirname(metadata_json_path),'.fixtures.yml')
        @fixtures = nil
        if @xref_fixtures && (File.file? fixtures_file)
          @fixtures = YAML.load_file fixtures_file
        end
      end


      # generate Puppetfile String from metadata.json & .fixtures.yml
      def to_puppetfile
       forge = ENV['PUPPET_FORGE'] || 'https://forgeapi.puppetlabs.com'
       result = %Q(forge "#{forge}"\n)

       @metadata.fetch('dependencies').each do |dep|
         name    =  dep['name'].sub('-','/')
         details = "'#{dep['version_requirement'].match(/(\d+(\.\d){0,2})/)}'"

         # git
         if @xref_fixtures && @fixtures
           fix_repos = @fixtures['fixtures'].fetch('repositories',{})
           _name = dep['name'].sub(/^[^-]+-/,'')
           if fix_repos.key? _name
             _details = fix_repos[_name]

             if _details.is_a?(String)
               details = "\n  :git => '#{_details}'"
             elsif (_details.is_a?(Hash) && _details.key?('repo') && _details.key?('ref') )
               details =  "\n  :git => '#{_details['repo']}',"
               details += "\n  :ref => '#{_details['ref']}'"
             else
               fail "ERROR: Unrecognized syntax in .fixtures.yml:\n" +
                    "---\n#{_details}'\n---\n"
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
