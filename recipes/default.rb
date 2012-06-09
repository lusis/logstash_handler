include_recipe "chef_handler"


cookbook_file "#{Chef::Config[:file_cache_path]}/chef-handler-logstash.rb" do
  source "chef-handler-logstash.rb"
  mode "0600"
end

chef_handler "LogstashReporting" do
  source "#{Chef::Config[:file_cache_path]}/chef-handler-logstash.rb"
  arguments [
              :host => node['chef_client']['handler']['logstash']['host'],
              :port => node['chef_client']['handler']['logstash']['port'],
              :tags => node['chef_client']['handler']['logstash']['tags']
            ]
  action :enable
end
