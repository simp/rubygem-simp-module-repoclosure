require 'spec_helper'
describe 'dep2' do

  context 'with default values for all parameters' do
    it { should contain_class('dep2') }
  end
end
