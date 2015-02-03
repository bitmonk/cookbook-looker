require_relative '../spec_helper'

describe 'looker::_service' do

  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe) }

  it 'Creates the looker service' do
    expect(chef_run).to start_service('looker')
  end

end
