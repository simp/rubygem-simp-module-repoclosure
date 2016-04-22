require 'spec_helper'
describe 'mut2' do

  context 'with default values for all parameters' do
    it { should contain_class('mut2') }
  end
end
