require 'spec_helper'
describe 'module01' do

  context 'with default values for all parameters' do
    it { should contain_class('module01') }
  end
end
