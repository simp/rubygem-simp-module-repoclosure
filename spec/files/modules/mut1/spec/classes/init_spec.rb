require 'spec_helper'
describe 'mut1' do

  context 'with default values for all parameters' do
    it { should contain_class('mut1') }
  end
end
