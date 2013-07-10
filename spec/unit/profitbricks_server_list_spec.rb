require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::ProfitbricksServerList.load_deps

describe Chef::Knife::ProfitbricksServerList do
  before do
    {
      :profitbricks_user => 'test',
      :profitbricks_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @server_list = Chef::Knife::ProfitbricksServerList.new
    @server = Profitbricks::Server.new(server_id: 'one', server_name: 'test', cores: 1, ram: 256)
    @profitbricks = mock(Profitbricks::Server)
  end

  it "should display all images" do
    @dc = mock(Profitbricks::DataCenter)
    @dc.should_receive(:servers).and_return [@server]
    @dc.should_receive(:name).and_return "test"
    Profitbricks::DataCenter.should_receive(:all).and_return [@dc]
    @server_list.ui.should_receive(:list).and_return ""
    @server_list.run
  end
end