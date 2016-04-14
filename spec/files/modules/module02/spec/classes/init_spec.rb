require 'spec_helper'
describe 'module02' do

  context 'with default values for all parameters' do
    it { should contain_class('module02') }
  end
end
