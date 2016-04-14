require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

  describe  '#puppetfile_from_metadata' do
    context "with no .fixtures.yml" do
      it 'should use Puppetfile forge syntax' do
        metadata_json = path_to_mock_module('module01', 'metadata.json')
        ci = Simp::Module::Repoclosure.new( metadata_json )
        puts text = ci.puppetfile_from_metadata()
        expect( text ).to match( /^mod 'stdlib', '4.1.0'/ )
        expect( text ).to match( /^mod 'simplib', '1.2.0'/ )
        #expect(File).to exist( File.join(ci.mut_dir,'Puppetfile') )
      end
    end

    context "with a .fixtures.yml containing a url-only repository" do
      it 'should use Puppetfile git syntax (repo-only)' do
        metadata_json = path_to_mock_module('module02', 'metadata.json')
        ci = Simp::Module::Repoclosure.new( metadata_json )
        puts text = ci.puppetfile_from_metadata()
        expect( text ).not_to match( /^mod 'simplib', '/ )
        expect( text ).to match( /^mod 'simplib',\s*\n\s*:git\s*=>\s*'/ )
        expect( text ).not_to match( /^mod 'simplib',\s*\n\s*:git\s*=>\s*'.*\n\s*:ref/ )
      end
    end

    context "with a .fixtures.yml containing a repository with a ref" do
      it 'should use Puppetfile git syntax w/ref' do
        metadata_json = path_to_mock_module('module02', 'metadata.json')
        ci = Simp::Module::Repoclosure.new( metadata_json )
        puts text = ci.puppetfile_from_metadata()
        expect( text ).not_to match( /^mod 'stdlib', '/ )
        expect( text ).to match( /^mod 'stdlib',\s*\n\s*:git\s*=>\s*'.*\n\s*:ref/ )
      end
    end
  end
end
