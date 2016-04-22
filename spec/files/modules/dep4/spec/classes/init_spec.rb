require 'spec_helper'
describe 'dep4' do

  context 'with default values for all parameters' do
    it { should contain_class('dep4') }
  end
end
