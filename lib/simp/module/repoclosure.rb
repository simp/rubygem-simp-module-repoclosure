require 'simp/module/repoclosure/version'
require 'simp/module/metadata'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'
require 'puppet_forge_server'
require 'parallel'



module Simp
  module Module
    class Repoclosure
      attr_accessor :verbose, :port
      def initialize( module_dir )
        @module_dir = module_dir

        # Puppet Forge to download dependencie modules from
        @upstream_puppet_forge='https://forgeapi.puppetlabs.com'


        metadata_json = File.join( module_dir, 'metadata.json' )
        @metadata = Simp::Module::Metadata.new(metadata_json)
        @verbose = ENV.fetch('VERBOSE', 0).to_i
        @port    = ENV['TEMP_FORGE_PORT'] || 8080
      end

      def do
        Dir.chdir '/tmp'
        tmp_dirs = []

        # directory containing tarballs for fake forge
        tut_dir = ENV.fetch('FAKE_FORGE_tarball_dir', nil)

        # directory containing modules
        mut_dir = ENV.fetch('FAKE_FORGE_module_dir', nil)

        module_dir = @module_dir
        begin
          if tut_dir.nil?
            tmp_dirs << tut_dir = Dir.mktmpdir('fakeforge_tut_dir_')
            if mut_dir.nil?
              tmp_dirs << mut_dir = Dir.mktmpdir('fakeforge_mut_dir_')
            end
          else
            fail "**************** TODO: just use the dir"
          end

          download_pupmods( module_dir, mut_dir )
          binding.pry
          package_tarballs( mut_dir, tut_dir )

          Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
        Dir.chdir '/tmp'
            success = run_fake_forge( tut_dir, pupmod_install_dir )
puts "success = '#{success}'"
          end
        ensure
          tmp_dirs.each do |dir|
        Dir.chdir '/tmp'
            FileUtils.remove_entry dir, :verbose => (@verbose > 0)
          end
        end
      end


      def run_fake_forge(  tut_dir, pupmod_install_dir )
        success = false
        cmd = "puppet module install #{@metadata.metadata.fetch('name')} --module_repository=http://localhost:#{@port} --modulepath=#{pupmod_install_dir}  --target-dir=#{pupmod_install_dir}"
        puts cmd
        pidfile = File.join(mut_dir,'fakeforge.pidfile')

        Parallel.map([1,2], in_processes: 2) do |x|
          Dir.chdir '/tmp'
          if x == 1
            puts "Starting fake forge (pidfile: '#{pidfile}'"
            PuppetForgeServer::Server.new.go([
              '-p', @port,
              '-b', 'localhost', '-m', tut_dir, '--pidfile', pidfile
            ])
          elsif x == 2
            sleep 5
            success = system(cmd)
            puts "$? = '#{$?}'"
    puts "success = '#{success}'"
            raise Parallel::Kill  # stops both Parallels
          end
        end
puts "success = '#{success}'"
        return success
      end


      def download_pupmods( module_dir, mut_dir )
        # build a puppet module_dir into an archive
        FileUtils.chdir module_dir, :verbose => (@verbose > 0 )
        cmd = "puppet module build  --render-as=json"
        puts cmd if @verbose > 0
        tgz = `#{cmd}`.split("\n").last.gsub('"','')
        puts "built module archive: #{tgz}" if @verbose > 0

        cmd = "puppet module install #{tgz} --module_repository=#{@upstream_puppet_forge} --modulepath=#{mut_dir}  --target-dir=#{mut_dir}"
        puts cmd if @verbose > 0
        out = `#{cmd}`
        puts out if @verbose > 0
      end




      def package_tarballs( mut_dir, tut_dir )
        pwd = Dir.pwd
        Dir[File.join(mut_dir, 'modules', '*')].each do |f|
          next unless File.directory? f
          FileUtils.chdir f, :verbose => (@verbose > 0)
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
            [
             #'bundle update',
             #'bundle exec rake build'
             'rake build'
            ].each do |cmd|
              line = "#{env_globals_line} #{cmd}"
              opts = {}
              opts = {:out => :close, :err => :close} if @verbose == 0
              exit 1 unless system(line, opts)
            end
          end
          Dir[File.join(Dir.pwd,'pkg','*.tar.gz')].each do |tgz|
            FileUtils.cp tgz, tut_dir, :verbose => (@verbose > 0)
          end
          FileUtils.chdir pwd, :verbose => (@verbose > 0)
        end
      end
    end
  end
end
