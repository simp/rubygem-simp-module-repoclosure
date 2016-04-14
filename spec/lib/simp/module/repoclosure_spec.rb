require 'spec_helper'
require 'simp/module/repoclosure'

describe Simp::Module::Repoclosure do
  it 'should have a VERSION constant' do
    expect(Simp::Module::Repoclosure.const_get('VERSION')).to_not be_empty
  end
end
