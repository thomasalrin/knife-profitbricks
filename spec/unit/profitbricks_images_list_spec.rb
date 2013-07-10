require File.expand_path('../../spec_helper', __FILE__)

Chef::Knife::ProfitbricksImageList.load_deps

describe Chef::Knife::ProfitbricksImageList do
  before do
    {
      :profitbricks_user => 'test',
      :profitbricks_password => 'test',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @image_list = Chef::Knife::ProfitbricksImageList.new
    @image = Profitbricks::Image.new(image_id: 'one', image_name: 'test', image_type: 'HDD', memory_hotpluggable: true, cpu_hotpluggable: true, size: 10, region: 'EUROPE')
    @profitbricks = mock(Profitbricks::Image)
  end

  it "should display all images" do
    Profitbricks::Image.should_receive(:all).and_return [@image]
    @image_list.ui.should_receive(:list).and_return ""
    @image_list.run
  end
end