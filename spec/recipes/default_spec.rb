require_relative '../spec_helper'

describe 'looker::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe) }
  let(:url) { 'https://s3.amazonaws.com/example' }
  let(:startup_script) { "#{url}/foo/looker" }
  let(:jar_file) { "#{url}/bar/looker-latest.jar" }
  let(:looker_run_dir) { "#{LOOKER_HOME}/looker" }
  let(:local_startup_script) { "#{looker_run_dir}/looker" }
  let(:local_jar_file) { "#{looker_run_dir}/looker.jar" }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
      node.set['looker']['run_dir'] = looker_run_dir
      node.set['looker']['startup_script_url'] = startup_script
      node.set['looker']['jar_file_url'] = jar_file
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

  it 'installs oracle java 7' do
    expect(chef_run).to include_recipe('java')
  end

  context 'When running with custom LOOKERARGS' do
    let(:looker_cfg) { "#{looker_run_dir}/lookerstart.cfg" }
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
        node.set['looker']['run_dir'] = looker_run_dir
        node.set['looker']['startup_script_url'] = startup_script
        node.set['looker']['jar_file_url'] = jar_file
        node.set['looker']['startup_args'] = '--ssl-keystore=/foo/bar.jks'
      end.converge(described_recipe)
    end

    it 'Creates lookerstart.cfg with the correct content' do
      expect(chef_run).to render_file(looker_cfg).with_content(
        /LOOKERARGS=\"--ssl-keystore=\/foo\/bar\.jks\"/
      )
    end

    it 'Starts the looker service' do
      expect(chef_run).to start_service('looker')
    end

    it 'Restarts looker when lookerstart.cfg is modified' do
      looker = chef_run.service('looker')
      expect(looker).to subscribe_to(
        "template[#{looker_cfg}]"
      )
    end
  end
end
