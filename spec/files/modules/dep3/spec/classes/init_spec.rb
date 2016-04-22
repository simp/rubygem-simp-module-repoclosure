require 'spec_helper'
describe 'dep3' do

  context 'with default values for all parameters' do
    it { should contain_class('dep3') }
  end
end
