require 'simp/module/repoclosure/version'
require 'simp/module/metadata'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'
require 'r10k/puppetfile'
require 'r10k/action/puppetfile/install'


module Simp
  module Module
    class Repoclosure
      attr_accessor :verbose
      def initialize( module_dir )
        metadata_json = File.join( module_dir, 'metadata.json' )
        @metadata = Simp::Module::Metadata.new(metadata_json)
        @verbose = 0
      end

      def do
        Dir.mktmpdir('fakeforge_mut_dir_') do |mut_dir|
          download_pupmods_into mut_dir

          Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
            package_tarballs mut_dir, tut_dir
            # TODO: fire up fake forge

            Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
            end
          end
        end
      end

      def package_tarballs( mut_dir, tut_dir )
        pwd = Dir.pwd
        Dir[File.join(mut_dir, 'modules', '*')].each do |f|
          next unless File.directory? f
          FileUtils.chdir f
          # propagate relevant environment variables
          env_globals = []
          [
            'PUPPET_VERSION',
            'STRICT_VARIABLES',
            'FUTURE_PARSER',
            'TRUSTED_NODE_DATA',
            'TRAVIS',
            'CI',
          ].each do |v|
            env_globals << %Q(#{v}="#{ENV[v]}") if ENV.key?( v )
          end
          env_globals_line = env_globals.join(' ')
          Bundler.with_clean_env do
            ['bundle update',
             'bundle exec rake build'].each do |cmd|
              line = "#{env_globals_line} #{cmd}"
              puts "==== EXECUTING: #{line}" unless @verbose == 0
              exit 1 unless system(line, {:out => :close, :err => :close})
            end
          end
          Dir[File.join(Dir.pwd,'pkg','*.tar.gz')].each do |tgz|
            FileUtils.cp tgz, tut_dir
          end
          FileUtils.chdir pwd
        end
      end

      # use r10k to install temporary pupmods
      def download_pupmods_into mut_dir
        FileUtils.chdir mut_dir
        puppetfile = @metadata.to_puppetfile
        File.open( File.join( mut_dir, 'Puppetfile' ), 'w' ){|f| f.puts puppetfile }
        r10k_pf   = R10K::Puppetfile.new( mut_dir )
        r10k_mods = r10k_pf.load!
        r10k_mods.each do |mod|
          puts "==== r10k: syncing pupmod '#{mod.name}' into '#{Dir.pwd}'" unless @verbose == 0
          mod.sync
        end
      end

    end
  end
end
