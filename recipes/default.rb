#
# Author:: John E. Vincent (<lusis.org+github.com@gmail.com>)
# Cookbook Name:: logstash_handler
# Recipe:: default
#
# Copyright 2012, John E. Vincent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "chef_handler"


cookbook_file "#{node['chef_handler']['handler_path']}/logstash_handler.rb" do
  source "logstash_handler.rb"
  mode "0600"
  action :nothing
end.run_action(:create)

if Chef::Config[:solo]
  logstash_type = 'chef-solo'
else
  logstash_type = 'chef-client'
end

chef_handler "CustomHandler::Logstash" do
  source "#{node['chef_handler']['handler_path']}/logstash_handler.rb"
  arguments [
              :host => node['chef_client']['handler']['logstash']['host'],
              :port => node['chef_client']['handler']['logstash']['port'],
              :tags => node['chef_client']['handler']['logstash']['tags'],
              :timeout => node['chef_client']['handler']['logstash']['timeout'],
              :type => logstash_type,
              :protocol => node['chef_client']['handler']['logstash']['protocol']
            ]
  action :nothing
end.run_action(:enable)
