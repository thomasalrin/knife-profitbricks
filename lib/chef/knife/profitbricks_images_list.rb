require 'chef/knife'
require 'chef/json_compat'

require_relative 'profitbricks_base'
class Chef
  class Knife
    class ProfitbricksImageList < Knife
      require_relative 'profitbricks_base'
      deps do
        require 'profitbricks'
        require 'highline'
        Chef::Knife.load_deps
      end

      include Chef::Knife::ProfitbricksBase

      banner "knife profitbricks image list OPTIONS"

      def run
        configure
        images = Profitbricks::Image.all

        image_list = [
            ui.color('ID', :bold),
            ui.color('Name', :bold),
            ui.color('Memory hotplug', :bold),
            ui.color('CPU hotplug', :bold),
            ui.color('Size', :bold),
            ui.color('Region', :bold),
        ]

        images.each do |i|
          next if i.type != "HDD"
          image_list << i.id
          image_list << i.name
          image_list << i.memory_hotpluggable.to_s
          image_list << i.cpu_hotpluggable.to_s
          image_list << i.size.to_s
          image_list << i.region.to_s
        end

        puts ui.list(image_list, :uneven_columns_across, 6)
      end
    end
  end
end
