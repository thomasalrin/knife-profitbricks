require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::ProfitbricksSnapshotCreate.load_deps

describe Chef::Knife::ProfitbricksSnapshotList do
  before do
    {
      :profitbricks_user => 'test',
      :profitbricks_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @snapshot_create = Chef::Knife::ProfitbricksSnapshotCreate.new
    @snapshot_create.stub(:puts)
  end

  it "should not run without a server id" do
    @snapshot_create.ui.should_receive(:error).with("A server id must be specified")
    lambda { @snapshot_create.run }.should raise_error SystemExit
  end

  it "should not run without a snapshot name" do
    Chef::Config[:knife][:profitbricks_server_id] = 'test'
    @snapshot_create.ui.should_receive(:error).with("You need to provide a name for the snapshot")
    lambda { @snapshot_create.run }.should raise_error SystemExit
  end

  it "should not run with servers with more then one connected storage" do
    server = Profitbricks::Server.new(:connected_storages => [{:id => '1234a'}, :id => '1234b'])
    Profitbricks::Server.should_receive(:find).and_return server
    Chef::Config[:knife][:profitbricks_server_id] = 'test'
    Chef::Config[:knife][:profitbricks_snapshot_name] = 'test'
    @snapshot_create.ui.should_receive(:error).with("This currently only works with servers with just one storage.")

    lambda { @snapshot_create.run }.should raise_error SystemExit
  end


  it "should run correctly" do
    server = Profitbricks::Server.new(:connected_storages => [:id => '1234a'])
    Profitbricks::Server.should_receive(:find).and_return server
    Profitbricks::Snapshot.should_receive(:create)
    Chef::Config[:knife][:profitbricks_server_id] = 'test'
    Chef::Config[:knife][:profitbricks_snapshot_name] = 'test'

    @snapshot_create.run
  end

end