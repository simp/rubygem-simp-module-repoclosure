require 'simp/module/repoclosure/version'
require 'json'
require 'yaml'
require 'pry'
require 'tmpdir'
require 'fileutils'
require 'puppet_forge_server'
require 'parallel'
require 'colorize'

module Simp
  module Module
    class Repoclosure
      attr_accessor :verbose, :port
      def initialize( tars_dir = nil, mods_dir = nil )

        # URL of upstream Puppet Forge to provide deps served by the test forge
        #
        # NOTE: The upstream forge will not be used if either of the env vars
        # `TEST_FORGE_mods_dir` or `TEST_FORGE_tars_dir` are present.
        @upstream_puppet_forge=  ENV.fetch('TEST_FORGE_deps_forge',
                                           'https://forgeapi.puppetlabs.com')
        @verbose = ENV.fetch('VERBOSE', 0).to_i
        @port    = ENV['TEST_FORGE_port'] || 8080

        # directory of tarballs for local forge
        @tars_dir = tars_dir || ENV.fetch('TEST_FORGE_tars_dir', nil)

        # directory to keep unarchived module dependencies
        @mods_dir = mods_dir || ENV.fetch('TEST_FORGE_mods_dir', nil)
      end

      def verbose?( level = 1 )
        @verbose >= level
      end

      def v1( msg, level = 1 )
        puts msg.colorize( :blue ) if verbose? 1
      end


      # mut_dirs = Array of (String) diectory paths to each module-to-test
      def test_modules( mut_dirs )
        Dir.chdir '/tmp' # ensure we start in a real directory
        tmp_dirs = []    # a list of directories we need to ensure are removed
        muts = []        # a list of forge names for MUTs

        begin
          if @tars_dir.nil?
            tmp_dirs << @tars_dir = Dir.mktmpdir('fakeforge_tars_dir_')
            if @mods_dir.nil?
              tmp_dirs << @mods_dir = Dir.mktmpdir('fakeforge_mods_dir_')
            end
          end

          # prepare a local forge to test against
          # -------------------------------------------------------------------
          # gather each module's forge name
          mut_dirs.each do |module_dir|
            mj_path  = File.expand_path('metadata.json', module_dir)
            metadata = JSON.parse(File.read(mj_path))
            muts << metadata.fetch('name')
          end

          # - download deps for each MUT (unless provided with a mods_dir)
          # - build tars from each MUT/dep (unless provided with a tars_dir)
          if @mods_dir
            if tmp_dirs.include?( @mods_dir )
              mut_dirs.each do |module_dir|
                download_mut_deps( module_dir )
              end
            end
            mod_dirs = Dir[File.join(@mods_dir,'*')].select{|x| File.directory? x}
            package_tarballs( mod_dirs )
          end

          # test the puppet modules in `mut_dirs` against local forge
          # -------------------------------------------------------------------
          Dir.mktmpdir('fakeforge_pupmod_inst_dir_') do |pupmod_install_dir|
            success = test_with_local_forge( muts, pupmod_install_dir )
v1 "success (pupmod_install_dir) = '#{success}'"
          end

        ensure
          tmp_dirs.each do |dir|
            Dir.chdir '/tmp'
            FileUtils.remove_entry dir, :verbose => verbose?
          end
        end
      end


      def test_with_local_forge( muts, pupmod_install_dir )
        pidfile = File.join(pupmod_install_dir,'fakeforge.pidfile')
        success = false

        Parallel.map([:forge,:mut_installer,:process_timeout], in_processes: 3) do |x|
          Dir.chdir '/tmp'
          if x == :forge
            start_local_forge(pidfile)
          elsif x == :mut_installer
            sleep 5  # safety wait for forge to spin up (never needed yet)
            success = test_install(muts, pupmod_install_dir)
            raise Parallel::Kill  # stops both Parallels
          elsif x == :process_timeout
            sleep 300
            raise Parallel::Kill  # stops both Parallels
          end
        end
v1 "success = '#{success}'"
        return success
      end

      # Starts a local puppet forge on port `@port`.
      def start_local_forge(pidfile)
        puts "Starting fake forge (module-dir: '#{@tars_dir}'  pidfile: '#{pidfile}'"
        PuppetForgeServer::Server.new.go([
          '--port', @port,
          '--bind', 'localhost',
          '--module-dir', @tars_dir,
          '--pidfile', pidfile
        ])
      end

      def test_install( muts, pupmod_install_dir )
        success = false
        muts.each do |mut|
          cmd = "puppet module install #{mut} " +
                "--module_repository=http://localhost:#{@port} " +
                "--modulepath=#{pupmod_install_dir}  " +
                "--target-dir=#{pupmod_install_dir}"
          v1 "RUNNING TEST: `#{cmd}`"
          success = system(cmd)
          puts "$? = '#{$?}'"
v1 "success for '#{mut}'  = '#{success}'"
          unless success
            puts ("mods_dir: " + @mods_dir.rjust(79)).colorize(:background => :red)
            puts `ls -la "#{@tars_dir}"`
            puts ("tars_dir: " + @tars_dir.rjust(79)).colorize(:background => :red)
            puts `ls -la "#{@tars_dir}"`
          end
        end
        success
      end

      # download all of the MUT's (declared) dependencies from an upstream
      # puppet forge into `@mods_dir/`
      def download_mut_deps( mut_dir )
        FileUtils.chdir mut_dir, :verbose => verbose?
        cmd = "puppet module build  --render-as=json"
        puts cmd if verbose?
        tgz = `#{cmd}`.split("\n").last.gsub('"','')
        puts "built module archive: #{tgz}" if verbose?
        cmd = "puppet module install #{tgz} " +
              "--module_repository=#{@upstream_puppet_forge} " +
              "--modulepath=#{@mods_dir}  --target-dir=#{@mods_dir}"
        v1 cmd
        out = `#{cmd}`
        v1 out

        # add the
        FileUtils.cp tgz, @tars_dir, :verbose => verbose?
      end


      # build a tarball of each module (in a directory of modules)
      # mods_dirs = Array of paths to directories of modules
      def package_tarballs( mods_dirs )
        pwd = Dir.pwd
        mods_dirs.each do |module_dir|
          next unless File.directory? module_dir
          FileUtils.chdir module_dir, :verbose => (verbose?)

          cmd = "puppet module build  --render-as=json"
          puts cmd if verbose?
          tgz = `#{cmd}`.split("\n").last.gsub('"','')
          puts "--[tgz] built module archive: #{tgz}" if verbose?
          FileUtils.cp tgz, @tars_dir, :verbose => verbose?
        end
        FileUtils.chdir pwd, :verbose => verbose?
      end
    end
  end
end
