require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

  describe '#package_tarballs' do
    it 'drops packages into the tarball_directory' do
      ci = Simp::Module::Repoclosure.new( path_to_mock_module('module02') )
      m1 = path_to_mock_module('module01')
      m2 = path_to_mock_module('module02')
      Dir.mktmpdir('fakeforge_spec_test_mut_dir_') do |mut_dir|
        FileUtils.mkdir_p  File.join(mut_dir, 'modules')
        FileUtils.cp_r m1, File.join(mut_dir, 'modules', 'module01')
        FileUtils.cp_r m2, File.join(mut_dir, 'modules', 'module02')
        Dir.mktmpdir('fakeforge_tut_dir_') do |tut_dir|
          ci.package_tarballs mut_dir, tut_dir
          expect(File).to exist( File.join( tut_dir, 'test-module01-0.1.0.tar.gz' ) )
          expect(File).to exist( File.join( tut_dir, 'test-module02-0.1.0.tar.gz' ) )
        end
      end
    end
  end

  describe '#do' do
    it 'does a do!' do
      ci = Simp::Module::Repoclosure.new( path_to_mock_module('module02') )
      ci.do
    end
  end
end
