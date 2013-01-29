require 'chef/knife'
require 'chef/json_compat'
require_relative 'profitbricks_base'

class Chef
  class Knife
    class ProfitbricksInitialize < Knife

      deps do
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'profitbricks'
        require 'highline'
        require 'chef/knife/bootstrap'
        require 'chef/knife/core/bootstrap_context'
        require 'securerandom'
        Chef::Knife.load_deps

      end
      include Knife::ProfitbricksBase
      

      banner "knife profitbricks initialize OPTIONS"

      option :datacenter_name,
        :short => "-D DATACENTER_NAME",
        :long => "--datacenter-name DATACENTER_NAME",
        :description => "The datacenter where the server will be created",
        :proc => Proc.new { |datacenter| Chef::Config[:knife][:profitbricks_datacenter] = datacenter }

      option :image_name,
        :short => "-i IMAGE_NAME",
        :long => "--image-name IMAGE_NAME",
        :description => "The image name which will be used to create the initial server 'template', default is 'profitbricks-ubuntu-12.04-server-amd64.img'",
        :default => 'profitbricks-ubuntu-12.04-server-amd64.img'

      option :user,
        :short => "-u USERNAME",
        :long => "--user USERNAME",
        :description => "The user to create and add the provided public key to authorized_keys, default is 'root'",
        :default => "root"

      option :public_key_file,
        :short => "-k PUBLIC_KEY_FILE",
        :long => "--public-key-file PUBLIC_KEY_FILE",
        :description => "The SSH public key file to be added to the authorized_keys of the given user, default is '~/.ssh/id_rsa.pub'",
        :default => "#{File.expand_path('~')}/.ssh/id_rsa.pub"

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!
        configure

        require 'pp'
        unless locate_config_value(:profitbricks_datacenter)
          ui.error("A Datacenter must be specified")
          exit 1
        end

        ui.info "Going to create an image which will be used to create new servers"
        msg_pair("Datacenter", locate_config_value(:profitbricks_datacenter))
        msg_pair("Image", locate_config_value(:image_name))

        puts ui.color("Locating Datacenter", :magenta)
        dc = DataCenter.find(:name => locate_config_value(:profitbricks_datacenter))

        # DELETEME
        dc.clear
        dc.wait_for_provisioning
        # DELETEME

        ## Setup storage and server
        puts ui.color("Locating Image", :magenta)
        image = Image.find(:name => locate_config_value(:image_name))

        hdd1 = Storage.create(:size => 5, :mount_image_id => image.id, :data_center_id => dc.id)
        wait_for(ui.color("Creating Storage", :magenta)) { dc.provisioned? }

        server = dc.create_server(:cores => locate_config_value(:profitbricks_cpus) || 1, 
                                  :ram => locate_config_value(:profitbricks_memory) || 1024, 
                                  :name => locate_config_value(:profitbricks_server_name) || "knife-profitbricks", 
                                  :boot_from_storage_id => hdd1.id, 
                                  :internet_access => true)
        wait_for(ui.color("Creating Server", :magenta)) { dc.provisioned? }

        wait_for(ui.color("Waiting for the Server to boot", :magenta)) { server.running? }
        server = Server.find(:id => server.id)
        msg_pair("ID", server.id)
        msg_pair("Name", server.name)
        msg_pair("Datacenter", dc.name)
        msg_pair("CPUs", server.cores.to_s)
        msg_pair("RAM", server.ram.to_s)
        msg_pair("IPs", (server.respond_to?("ips") ? server.ips : ""))
        
        if !server.respond_to?("ips") || server.ips == ""
          ui.error("The server does not to seem to be accessible")
          server.delete
          hdd1.delete
          exit 1
        end

        ## Change the default password
        @server = server.ips
        puts ui.color("Preparing the image to be used for provisioning new servers", :green)
        
        puts "Please check you EMail for the root password for the storage #{hdd1.id}"
        prompt_for_password

        @new_password = SecureRandom.hex
        change_password
        @password = @new_password
        puts ui.color("Changed the password successfully", :green)

        ## SSH Key
        dot_ssh_path = ""
        if locate_config_value(:user) != 'root'
          ssh("useradd #{locate_config_value(:user)} -G sudo -m")
          dot_ssh_path = "/home/#{locate_config_value(:user)}/.ssh"
        else
          dot_ssh_path = "/root/.ssh"
        end

        ssh_key = begin
          File.open(locate_config_value(:public_key_file)).read 
        rescue Exception => e
          ui.error(e.message)
          ui.error("Could not read the provided public ssh key, check the public_key_file config.")
          exit 1
        end
        ssh("mkdir -p #{dot_ssh_path} && echo \"#{ssh_key}\" > #{dot_ssh_path}/authorized_keys && chmod -R go-rwx #{dot_ssh_path}").run
        puts ui.color("Added the ssh key to the authorized_keys of #{locate_config_value(:user)}", :green)

        ## Image uploading
        puts ui.color("Uploading the image to the profitbricks ftp server for later usage (this will take a few minutes)", :magenta)
        ssh("sed -i 's/#GRUB_HIDDEN_TIMEOUT=0/GRUB_HIDDEN_TIMEOUT=0/' /etc/default/grub && grub-install /dev/sda && dd if=/dev/sda conv=sync bs=1M | curl -u #{profitbricks_user}:#{profitbricks_password} ftp://upload.de.profitbricks.com/hdd-images/knife-profitbricks.img -T - &> /dev/null").run

        ## Cleanup
        #server.delete
        #hdd1.delete
        wait_for(ui.color("Image uploaded deleting server", :green)) { dc.provisioned? }
        puts ui.color("Done, you can now create new servers using your template storage with 'knife profitbricks server create'", :green)
      end

      def prompt_for_password(prompt = "Your password: ")
        @password = ui.ask(prompt) { |q| q.echo = false }
      end

      def change_password
        begin
          Net::SSH.start( @server, 'root', :password =>@password, :paranoid => false ) do |ssh|
            ssh.open_channel do |channel|
               channel.on_request "exit-status" do |channel, data|
                  $exit_status = data.read_long
               end
               channel.on_data do |channel, data|
                  if data.inspect.include? "current"
                          channel.send_data("#{@password}\n");
                  elsif data.inspect.include? "new"
                          channel.send_data("#{@new_password}\n");
                  end
               end
               channel.request_pty
               channel.exec("passwd");
               channel.wait

               return $exit_status == 0
            end
          end
        rescue Net::SSH::AuthenticationFailed
          prompt_for_password
          change_password
        end
      end

    end
  end
end
