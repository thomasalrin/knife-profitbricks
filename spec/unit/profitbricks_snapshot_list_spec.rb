require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::ProfitbricksSnapshotList.load_deps

describe Chef::Knife::ProfitbricksSnapshotList do
  before do
    {
      :profitbricks_user => 'test',
      :profitbricks_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @snapshot_list = Chef::Knife::ProfitbricksSnapshotList.new
    @snapshot = Profitbricks::Snapshot.new(id: '1234a', name: 'test', ram_hot_plug: true, cpu_hot_plug: true, size: 10, region: 'EUROPE')
    @profitbricks = mock(Profitbricks::Snapshot)
  end

  it "should display all images" do
    Profitbricks::Snapshot.should_receive(:all).and_return [@snapshot]
    @snapshot_list.ui.should_receive(:list).and_return ""
    @snapshot_list.run
  end
end