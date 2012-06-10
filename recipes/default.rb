include_recipe "chef_handler"


cookbook_file "#{node['chef_handler']['handler_path']}/logstash_handler.rb" do
  source "logstash_handler.rb"
  mode "0600"
end

chef_handler "Chef::Handler::Logstash" do
  source "#{node['chef_handler']['handler_path']}/logstash_handler.rb"
  arguments [
              :host => node['chef_client']['handler']['logstash']['host'],
              :port => node['chef_client']['handler']['logstash']['port'],
              :tags => node['chef_client']['handler']['logstash']['tags'],
              :timeout => node['chef_client']['handler']['logstash']['timeout']
            ]
  action :enable
end
