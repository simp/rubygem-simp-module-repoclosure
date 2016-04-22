require 'spec_helper'
require 'simp/module/repoclosure'
require 'tmpdir'

describe Simp::Module::Repoclosure do
  before :each do
      Dir.chdir(File.dirname(__FILE__))  # avoids post-mktempdir errors
  end

  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

### FIXME: optional stdlib test
###  describe '#download_mut_deps' do
###    it 'downloads pupmod deps into the mods directory' do
###      module_dir = path_to_mock_module('mut1')
###      Dir.mktmpdir('fakeforge_spec_test_mods_dir_') do |tars_dir|
###        Dir.mktmpdir('fakeforge__mods_dir_SPEC_TEST') do |mods_dir|
###          ci = Simp::Module::Repoclosure.new( tars_dir, mods_dir )
###          ci.download_mut_deps module_dir
###          expect(File).to exist( File.join( mods_dir, 'dep1' ) )
###          expect(File).to exist( File.join( mods_dir, 'dep2' ) )
###        end
###      end
###    end
###  end

  describe '#package_tarballs' do
    it 'places tarballs into the destination directory' do

      m1 = path_to_mock_module('module01')
      Dir.mktmpdir('fakeforge_spec_test_mods_dir_') do |mods_dir|
        tmp_m1 = File.join(mods_dir, 'module01')
        FileUtils.cp_r m1, tmp_m1

        Dir.mktmpdir('fakeforge_tars_dir_') do |tars_dir|
          ci = Simp::Module::Repoclosure.new(tars_dir)
          ci.package_tarballs([tmp_m1])
          expect(File).to exist(File.join(tars_dir, 'test-module01-0.1.0.tar.gz'))
        end
      end
    end
  end

  describe '#test_modules' do
    context '#using a pre-existing `@mods_dir`' do
      it 'does a do!' do
        m1 = path_to_mock_module('mut1')
        d1 = path_to_mock_module('dep1')
        d2 = path_to_mock_module('dep2')
        Dir.mktmpdir('fakeforge_spec_test_mods_dir_') do |mods_dir|
          [m1,d1,d2].each do |p|
            FileUtils.cp_r(p, File.join(mods_dir,File.basename(p)))
          end
          Dir.mktmpdir('fakeforge_spec_test_tars_dir_') do |tars_dir|
            ci = Simp::Module::Repoclosure.new( tars_dir, mods_dir )
            ci.verbose = 0
            result = ci.test_modules([m1])
            #expect( result ).to eq false
          end
        end
      end
    end
###    context '#using unset `@tars_dir` and `@mods_dir` (mktempdir)' do
###      it 'does a do!' do
###        m1 = path_to_mock_module('module01')
###        ci = Simp::Module::Repoclosure.new
###        ci.verbose = 1
###        ci.test_modules([m1])
###        # FIXME: fails because the modss aren't built and copied into the tars_dir
###        # FIXME: how to test
###      end
###    end
###
###    context '#using a pre-existing `@tars_dir`' do
###      it 'does a do!' do
###        m1 = path_to_mock_module('module01')
###        Dir.mktmpdir('fakeforge_tars_dir_') do |tars_dir|
###          ci = Simp::Module::Repoclosure.new( tars_dir )
###          ci.verbose = 1
###          ci.test_modules([m1])
###          # FIXME: how to test
###        end
###      end
###    end
  end
end
