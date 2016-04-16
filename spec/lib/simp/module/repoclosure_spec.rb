require 'spec_helper'
require 'simp/module/repoclosure'
require 'tmpdir'

describe Simp::Module::Repoclosure do
  before :each do
      Dir.chdir(File.dirname(__FILE__))  # avoids mktempdir errors
  end

  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

  describe '#download_pupmods_into' do
    it 'downloads pupmods into the mut directory (forge)' do
      Dir.mktmpdir('fakeforge_spec_test_mut_dir_') do |mut_dir|
        module_dir = path_to_mock_module('module01')
        ci = Simp::Module::Repoclosure.new( module_dir )
        Dir.mktmpdir('fakeforge__mut_dir_SPEC_TEST') do |mut_dir|
          ci.download_pupmods module_dir, mut_dir
          expect(File).to exist( File.join( mut_dir, 'stdlib' ) )
          expect(File).to exist( File.join( mut_dir, 'module01' ) )
        end
      end
    end

    it 'downloads pupmods into the mut directory (git)' do
      Dir.mktmpdir('fakeforge__mut_dir_SPEC_TEST') do |mut_dir|
        module_dir = path_to_mock_module('module02')
        ci = Simp::Module::Repoclosure.new( module_dir )
        ci.download_pupmods module_dir, mut_dir
        expect(File).to exist( File.join( mut_dir, 'stdlib' ) )
        expect(File).to exist( File.join( mut_dir, 'module02' ) )
      end
    end
  end

  describe '#package_tarballs' do
    it 'places tarballs into the destination directory' do

      ci = Simp::Module::Repoclosure.new( path_to_mock_module('module01') )
      m1 = path_to_mock_module('module01')
      Dir.mktmpdir('fakeforge_spec_test_mut_dir_') do |mut_dir|
        FileUtils.cp_r m1, File.join(mut_dir, 'module01')
        Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
          ci.package_tarballs mut_dir, tut_dir
          expect(File).to exist( File.join( tut_dir, 'test-module01-0.1.0.tar.gz' ) )
        end
      end
    end
  end

  describe '#do' do
    it 'does a do!' do
      module_dir = path_to_mock_module('module01')
      ci = Simp::Module::Repoclosure.new( module_dir )
      ci.verbose = 1
      ci.do
    end
  end
end
