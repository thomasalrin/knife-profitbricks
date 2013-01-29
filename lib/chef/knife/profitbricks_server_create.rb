require 'chef/knife'
require 'chef/json_compat'
require_relative 'profitbricks_base'

class Chef
  class Knife
    class ProfitbricksServerCreate < Knife

      deps do
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'profitbricks'
        require 'highline'
        require 'chef/knife/bootstrap'
        require 'chef/knife/core/bootstrap_context'
        Chef::Knife.load_deps

      end
      include Knife::ProfitbricksBase
      

      banner "knife profitbricks server create OPTIONS"

      option :datacenter_name,
        :short => "-D DATACENTER_NAME",
        :long => "--datacenter-name DATACENTER_NAME",
        :description => "The datacenter where the server will be created",
        :proc => Proc.new { |datacenter| Chef::Config[:knife][:profitbricks_datacenter] = datacenter }

      option :name,
        :long => "--name SERVER_NAME",
        :description => "name for the newly created Server",
        :proc => Proc.new { |image| Chef::Config[:knife][:profitbricks_server_name] = image }


      option :memory,
        :long => "--ram RAM",
        :description => "Amount of Memory in MB of the new Server",
        :proc => Proc.new { |memory| Chef::Config[:knife][:profitbricks_memory] = memory }

      option :cpus,
        :long => "--cpus CPUS",
        :description => "Amount of CPUs of the new Server",
        :proc => Proc.new { |cpus| Chef::Config[:knife][:profitbricks_cpus] = cpus }
      
      option :hdd_size,
        :long => "--hdd-size GB",
        :description => "Size of storage in GB",
        :default => 25

      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server with knife bootstrap",
        :boolean => true,
        :default => true

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication",
        :default => "#{File.expand_path('~')}/.ssh/id_rsa"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu12.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu12.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node default is the name of the server.",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }



      def h
        @highline ||= HighLine.new
      end

      def run
        validate!
        configure


        require 'pp'
        unless Chef::Config[:knife][:profitbricks_datacenter]
          ui.error("A Datacenter must be specified")
          exit 1
        end

        unless Chef::Config[:knife][:profitbricks_server_name]
          ui.error("You need to provide a name for the server")
          exit 1
        end

        unless Chef::Config[:knife][:profitbricks_server_name]
          ui.error("The name for the server must be specified")
          exit 1
        end

        if !Image.all.collect(&:name).include? 'knife-profitbricks.img'
          ui.error("Could not locate the prepared image. You need to run 'knife profitbricks initialize' first.")
          exit 1         
        end

        ui.info "Going to create a new server"
        msg_pair("Name", Chef::Config[:knife][:profitbricks_server_name])
        msg_pair("Datacenter", Chef::Config[:knife][:profitbricks_datacenter])
        msg_pair("Image", Chef::Config[:knife][:profitbricks_image])
        msg_pair("CPUs", Chef::Config[:knife][:profitbricks_cpus] || 1)
        msg_pair("Memory", Chef::Config[:knife][:profitbricks_memory] || 1024)

        datacenters = Profitbricks::DataCenter.all

        puts "#{ui.color("Locating Datacenter", :magenta)}"
        dc = DataCenter.find(:name => Chef::Config[:knife][:profitbricks_datacenter])

        # FIXME
        dc.clear
        dc.wait_for_provisioning

        puts "#{ui.color("Locating Image", :magenta)}"
        image = Image.find(:name => 'knife-profitbricks.img')


        hdd1 = Storage.create(:size => locate_config_value(:hdd_size), :mount_image_id => image.id, :data_center_id => dc.id)
        wait_for("#{ui.color("Creating Storage", :magenta)}") { dc.provisioned? }

        server = dc.create_server(:cores => Chef::Config[:knife][:profitbricks_cpus] || 1, 
                                  :ram => Chef::Config[:knife][:profitbricks_memory] || 1024, 
                                  :name => Chef::Config[:knife][:profitbricks_server_name] || "Server", 
                                  :boot_from_storage_id => hdd1.id, 
                                  :internet_access => true)
        wait_for("#{ui.color("Creating Server", :magenta)}") { dc.provisioned? }

        puts "#{ui.color("Done creating new Server", :green)}"
        wait_for("#{ui.color("Waiting for the Server to boot", :magenta)}") { server.running? }
        server = Server.find(:id => server.id)
        msg_pair("ID", server.id)
        msg_pair("Name", server.name)
        msg_pair("Datacenter", dc.name)
        msg_pair("CPUs", server.cores.to_s)
        msg_pair("RAM", server.ram.to_s)
        msg_pair("IPs", (server.respond_to?("ips") ? server.ips : ""))
        
        @server = server.ips

        server = DataCenter.find(:name => Chef::Config[:knife][:profitbricks_datacenter]).servers.first
        @server = server.ips

        if !config[:bootstrap]
          exit 0
        end

        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = @server
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = @password
        bootstrap.config[:host_key_verify] = false
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.name
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.run
      end
    end
  end
end
