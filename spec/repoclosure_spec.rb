require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  it 'should have a VERSION constant' do
    expect(subject.const_get('VERSION')).to_not be_empty
  end


  describe '#build_puppetfile' do
    it 'should create a Puppetfile' do
      metadata_json = File.expand_path('files/metadata.json', File.dirname(__FILE__))
      puppetfile    =  File.expand_path('files/Puppetfile', File.dirname(__FILE__))
      ci = Simp::Module::Repoclosure.new( metadata_json )
      ci.build_puppetfile( )
      expect(File).to exist( puppetfile )
    end
  end
end
