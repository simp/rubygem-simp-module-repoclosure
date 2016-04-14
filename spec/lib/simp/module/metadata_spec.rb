require 'spec_helper'
require 'simp/module/metadata'

describe Simp::Module::Metadata do
  describe  '#to_puppetfile' do
    context "with no .fixtures.yml" do
      it 'should use Puppetfile forge syntax' do
        metadata_json = path_to_mock_module('module01', 'metadata.json')
        ci = Simp::Module::Metadata.new( metadata_json )
        text = ci.to_puppetfile()
        expect( text ).to match( %r(^mod 'puppetlabs/stdlib', '4.1.0') )
      end
    end

    context "with a .fixtures.yml containing a repository with a ref" do
      it 'should use Puppetfile git syntax w/ref' do
        metadata_json = path_to_mock_module('module02', 'metadata.json')
        ci = Simp::Module::Metadata.new( metadata_json )
        text = ci.to_puppetfile()
        expect( text ).not_to match( /^mod 'stdlib', '/ )
        expect( text ).to match( /^mod 'stdlib',\s*\n\s*:git\s*=>\s*'.*,\s*\n\s*:ref/ )
      end
    end

    context "with a .fixtures.yml containing a url-only repository" do
      it 'should use Puppetfile git syntax (repo-only)' do
        metadata_json = path_to_mock_module('module03', 'metadata.json')
        ci = Simp::Module::Metadata.new( metadata_json )
        text = ci.to_puppetfile()
        expect( text ).not_to match( /^mod 'stdlib', '/ )
        expect( text ).to match( /^mod 'stdlib',\s*\n\s*:git\s*=>\s*'/ )
        expect( text ).not_to match( /^mod 'stdlib',\s*\n\s*:git\s*=>\s*'.*\n\s*:ref/ )
      end
    end
  end
end
