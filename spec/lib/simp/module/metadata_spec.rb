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
  end
end
