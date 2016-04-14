require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  before :each do
      Dir.chdir(File.dirname(__FILE__))  # avoids mktempdir errors
  end

  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

  describe '#download_pupmods_into' do
    it 'downloads pupmods into the mut directory' do
      Dir.mktmpdir('fakeforge_spec_test_mut_dir_') do |mut_dir|
        ci = Simp::Module::Repoclosure.new( path_to_mock_module('module02') )
        ci.download_pupmods_into mut_dir
        expect(File).to exist( File.join( mut_dir, 'Puppetfile' ) )
        expect(File).to exist( File.join( mut_dir, 'modules' , 'stdlib' ) )
        expect(File).to exist( File.join( mut_dir, 'modules' , 'module02' ) )
      end
    end
  end

  describe '#package_tarballs' do
    it 'places tarballs into the destination directory' do
      ci = Simp::Module::Repoclosure.new( path_to_mock_module('module02') )
      m1 = path_to_mock_module('module01')
      Dir.mktmpdir('fakeforge_spec_test_mut_dir_') do |mut_dir|
        FileUtils.mkdir_p  File.join(mut_dir, 'modules')
        FileUtils.cp_r m1, File.join(mut_dir, 'modules', 'module01')
        Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
          ci.package_tarballs mut_dir, tut_dir
          expect(File).to exist( File.join( tut_dir, 'test-module01-0.1.0.tar.gz' ) )
        end
      end
    end
  end

  describe '#do' do
    it 'does a do!' do
            Dir.chdir '/tmp'
      ci = Simp::Module::Repoclosure.new( path_to_mock_module('module01') )
      ci.verbose = 1
      ci.do
    end
  end
end
