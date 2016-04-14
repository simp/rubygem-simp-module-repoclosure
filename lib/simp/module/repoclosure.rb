require 'simp/module/repoclosure/version'
require 'simp/module/metadata'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'
require 'r10k/puppetfile'
require 'puppet_forge_server'
require 'parallel'
#require 'puppet_forge_server/backends/directory'
#require 'puppet_forge_server/app/version3'



module Simp
  module Module
    class Repoclosure
      attr_accessor :verbose
      def initialize( module_dir )
        @module_dir = module_dir
        metadata_json = File.join( module_dir, 'metadata.json' )
        @metadata = Simp::Module::Metadata.new(metadata_json)
        @verbose = 0
      end

      def do
        Dir.chdir '/tmp'
        Dir.mktmpdir('fakeforge_mut_dir_') do |mut_dir|
          download_pupmods_into mut_dir
          Dir.chdir '/tmp'

          Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
            package_tarballs mut_dir, tut_dir
            Dir.chdir '/tmp'



            Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
              # TODO: fire up fake forge in parallel process



              Dir.chdir '/tmp'
              forge_be = PuppetForgeServer::Backends::Directory.new(tut_dir,false)
              forge_server = PuppetForgeServer::App::Version3.new [forge_be]

              binding.pry
              Parallel.map([1,2], in_processes: 2) do |x|
            Dir.chdir '/tmp'
                if x == 1
                  PuppetForgeServer::Server.new.go([
                    '-p','8080','-b','localhost','-m',tut_dir,
                    '-D','--pidfile',File.join(mut_dir,'fakeforge.pidfile')
                  ])
                elsif x == 2
                  sleep 5
                  cmd = "puppet module install test-module02 --module_repository=http://localhost:8080 --modulepath=#{pupmod_install_dir}"
                  puts cmd
                  puts `#{cmd}`
                end
              end
            end
          end
        end
      end

      # use r10k to install temporary pupmods
      def download_pupmods_into mut_dir
        FileUtils.chdir mut_dir
        mod_dir = File.join(mut_dir,'modules')
        puppetfile = @metadata.to_puppetfile
        File.open( File.join( mut_dir, 'Puppetfile' ), 'w' ){|f| f.puts puppetfile }
        binding.pry
        r10k_pf   = R10K::Puppetfile.new( mut_dir )
        r10k_mods = r10k_pf.load!
        r10k_mods.each do |mod|
          puts "==== r10k: syncing pupmod '#{mod.name}' into '#{Dir.pwd}'" unless @verbose == 0
          mod.sync
        end

        binding.pry
        # copy in MUT
        FileUtils.mkdir_p mod_dir
        FileUtils.cp_r @module_dir, File.join(mod_dir,File.basename(@module_dir))
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
              opts = {}
              opts = {:out => :close, :err => :close} if @verbose == 0
              exit 1 unless system(line, opts)
            end
          end
          Dir[File.join(Dir.pwd,'pkg','*.tar.gz')].each do |tgz|
            FileUtils.cp tgz, tut_dir
          end
          FileUtils.chdir pwd
        end
      end
    end
  end
end
