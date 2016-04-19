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
      def initialize( tut_dir = nil, mut_dir = nil )

        # URL of Puppet Forge to provide upstream dependencies
        @upstream_puppet_forge='https://forgeapi.puppetlabs.com'


        @verbose = ENV.fetch('VERBOSE', 0).to_i
        @port    = ENV['TEST_FORGE_port'] || 8080

        @temp_dirs = []

        # directory containing tarballs for fake forge
        @tut_dir = tut_dir || ENV.fetch('TEST_FORGE_tarball_dir', nil)

        # directory containing modules
        @mut_dir = mut_dir || ENV.fetch('TEST_FORGE_module_dir', nil)

        # TODO: mktempdir
      end

      def verbose?( level = 1 )
        @verbose >= level
      end


      def test_modules( module_dirs )
        Dir.chdir '/tmp'
        tmp_dirs = []
        pupmods  = []

        begin
          if @tut_dir.nil?
            tmp_dirs << @tut_dir = Dir.mktmpdir('fakeforge_tut_dir_')
            if @mut_dir.nil?
              tmp_dirs << @mut_dir = Dir.mktmpdir('fakeforge_mut_dir_')
            end
          end

          # get each module's name & dependencies
          module_dirs.each do |module_dir|
            mj_path  = File.expand_path('metadata.json', module_dir)
            metadata = JSON.parse(File.read(mj_path))
            pupmods << metadata.fetch('name')
            download_pupmod_deps( module_dir )
          end

          # build tarballs for local forge
          mod_dirs = Dir[File.join(@mut_dir,'*')].select{|x| File.directory? x}
          package_tarballs( mod_dirs )

          # run tests
          Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
            success = test_with_local_forge( pupmods, pupmod_install_dir )
puts "success = '#{success}'"
          end

        ensure
          tmp_dirs.each do |dir|
            Dir.chdir '/tmp'
            FileUtils.remove_entry dir, :verbose => verbose?
          end
        end
      end


      def test_with_local_forge( pupmods, pupmod_install_dir )
        pidfile = File.join(pupmod_install_dir,'fakeforge.pidfile')
        success = false

        Parallel.map([:process_1,:process_2], in_processes: 2) do |x|
          Dir.chdir '/tmp'
          if x == :process_1
            puts "Starting fake forge (module-dir: '#{@tut_dir}'  pidfile: '#{pidfile}'"
            PuppetForgeServer::Server.new.go([
              '--port', @port,
              '--bind', 'localhost',
              '--module-dir', @tut_dir,
              '--pidfile', pidfile
            ])
          elsif x == :process_2
            sleep 5  # safety wait for forge to spin up (never needed yet)

            pupmods.each do |pupmod|
              cmd = "puppet module install #{pupmod} " +
                    "--module_repository=http://localhost:#{@port} " +
                    "--modulepath=#{pupmod_install_dir}  " +
                    "--target-dir=#{pupmod_install_dir}"
              puts "RUNNING TEST: `#{cmd}`" if verbose?
              success = system(cmd)
              puts "$? = '#{$?}'"
puts "success for '#{pupmod}'  = '#{success}'"
              end
            raise Parallel::Kill  # stops both Parallels
          end
        end
puts "success = '#{success}'"
        return success
      end


      # download all of the module's (declared) dependencies from an
      # upstream puppet forge into `@mut_dir/`
      def download_pupmod_deps( module_dir )
        # build a puppet module_dir into an archive
        FileUtils.chdir module_dir, :verbose => verbose?
        cmd = "puppet module build  --render-as=json"
        puts cmd if verbose?
        tgz = `#{cmd}`.split("\n").last.gsub('"','')
        puts "built module archive: #{tgz}" if verbose?

        cmd = "puppet module install #{tgz} " + 
              "--module_repository=#{@upstream_puppet_forge} " +
              "--modulepath=#{@mut_dir}  --target-dir=#{@mut_dir}"
        puts cmd if verbose?
        out = `#{cmd}`
        puts out if verbose?
      end


      # build a tarball of each module in a directory of modules
      def package_tarballs( mod_dir_list )
        pwd = Dir.pwd
        mod_dir_list.each do |module_dir|
          next unless File.directory? module_dir
          FileUtils.chdir module_dir, :verbose => (verbose?)

          cmd = "puppet module build  --render-as=json"
          puts cmd if verbose?
          tgz = `#{cmd}`.split("\n").last.gsub('"','')
          puts "--[tgz] built module archive: #{tgz}" if verbose?
          FileUtils.cp tgz, @tut_dir, :verbose => verbose?
        end
        FileUtils.chdir pwd, :verbose => verbose?
      end
    end
  end
end
