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
            fail "**************** TODO: just use the tarball dir"
          end

          download_pupmods( module_dir, mut_dir )
          package_tarballs( mut_dir, tut_dir )

          Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
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
        pidfile = File.join(pupmod_install_dir,'fakeforge.pidfile')

        Parallel.map([1,2], in_processes: 2) do |x|
          Dir.chdir '/tmp'
          if x == 1
            puts "Starting fake forge (module-dir: '#{tut_dir}'  pidfile: '#{pidfile}'"
            PuppetForgeServer::Server.new.go([
              '--port', @port,
              '--bind', 'localhost',
              '--module-dir', tut_dir,
              '--pidfile', pidfile
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
        Dir[File.join(mut_dir, '*')].each do |module_dir|
          next unless File.directory? module_dir
          FileUtils.chdir module_dir, :verbose => (@verbose > 0)

          cmd = "puppet module build  --render-as=json"
          puts cmd if @verbose > 0
          tgz = `#{cmd}`.split("\n").last.gsub('"','')
          puts "--[tgz] built module archive: #{tgz}" if @verbose > 0
          FileUtils.cp tgz, tut_dir, :verbose => (@verbose > 0)
        end
        FileUtils.chdir pwd, :verbose => (@verbose > 0)
      end
    end
  end
end
