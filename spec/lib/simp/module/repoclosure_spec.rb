require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end

  it 'does a do!' do
    ci = Simp::Module::Repoclosure.new( path_to_mock_module('module02') )
    ci.do
  end
end
