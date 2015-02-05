require_relative '../spec_helper'


describe 'looker::_install' do
  url = 'https://s3.amazonaws.com/example'
  startup_script = "#{url}/foo/looker"
  jar_file = "#{url}/bar/looker-latest.jar"

  looker_run_dir = "#{LOOKER_HOME}/looker"
  local_startup_script = "#{looker_run_dir}/looker"
  local_jar_file = "#{looker_run_dir}/looker.jar"

  let(:chef_run) do 
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
      node.set['looker']['run_dir'] = looker_run_dir
      node.set['looker']['startup_script'] = startup_script
      node.set['looker']['jar_file'] = jar_file
    end.converge(described_recipe) 
  end

  it 'Creates the looker group' do
    expect(chef_run).to create_group('looker')
  end

  it 'Creates the looker user' do
    expect(chef_run).to create_user('looker').with(
      'supports' => { :manage_home => true },
      'home' => LOOKER_HOME,
      'shell' => '/bin/sh',
      'gid' => 'looker'
    )
  end

  it 'Creates the looker running directory' do
    expect(chef_run).to create_directory(looker_run_dir).with(
      'owner' => 'looker',
      'group' => 'looker'
    )
  end

  it 'Gets the looker startup script from remote' do
    expect(chef_run).to create_remote_file_if_missing(local_startup_script).with(
      source: startup_script,
      owner: 'looker',
      group: 'looker',
      mode: 0750,
      action: [ :create_if_missing ]
    )
  end

  it 'Gets the looker jar file from remote' do
    expect(chef_run).to create_remote_file_if_missing(local_jar_file).with(
      source: jar_file,
      owner: 'looker',
      group: 'looker',
      mode: 0750,
      action: [ :create_if_missing ]
    )
  end

end
