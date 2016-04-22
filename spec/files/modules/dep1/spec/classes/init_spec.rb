require 'spec_helper'
describe 'dep1' do

  context 'with default values for all parameters' do
    it { should contain_class('dep1') }
  end
end
