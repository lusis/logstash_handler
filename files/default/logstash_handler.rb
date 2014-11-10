#
# Author:: John E. Vincent <lusis.org+github.com@gmail.com>
# Copyright:: Copyright (c) 2012, John E. Vincent
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef"
require "chef/handler"
require "socket"
require "timeout"

module CustomHandler
  class Logstash < Chef::Handler
    attr_writer :tags, :host, :port, :timeout
  
    def initialize(options = {})
      options[:tags] ||= Array.new
      options[:timeout] ||= 15
      @tags = options[:tags]
      @timeout = options[:timeout]
      @host = options[:host]
      @port = options[:port]
    end
  
    def report
      # A logstash json_event looks like this:
      # {
      #   "@source":"typicall determined by logstash input def",
      #   "@type":"determined by logstash input def",
      #   "@tags":[],
      #   "@fields":{},
      #   "@timestamp":"ISO8601 of event seen by logstash",
      #   "@source_host":"host.foo.com",
      #   "@source_path":"typically the name of the log file",
      #   "@message":"escaped representation of event"
      # }
      #
      # When sending an event in native `json_event` format
      # - You are required to set everything EXCEPT @type and @timestamp
      # - @type CAN be overridden
      # - @timestamp will be ignored
  
      @updated_resources = []
      if run_status.updated_resources
        run_status.updated_resources.each {|r| @updated_resources << r.to_s }
      end
      event = Hash.new
      event["@source"] = "chef://#{run_status.node.name}/handler/logstash"
      event["@source_path"] = "#{__FILE__}"
      event["@source_host"] = run_status.node.name
      event["@tags"] = @tags
      event["@fields"] = Hash.new
      event["@fields"]["updated_resources"] = @updated_resources
      event["@fields"]["elapsed_time"] = run_status.elapsed_time
      event["@fields"]["success"] = run_status.success?
      # (TODO) Convert to ISO8601
      event["@fields"]["start_time"] = run_status.start_time.to_time.iso8601
      event["@fields"]["end_time"] = run_status.end_time.to_time.iso8601
      if run_status.backtrace
        event["@fields"]["backtrace"] = run_status.backtrace.join("\n")
      else
        event["@fields"]["backtrace"] = ""
      end
      if run_status.exception
        event["@fields"]["exception"] = run_status.exception
      else
        event["@fields"]["exception"] = ""
      end
      event["@message"] = run_status.exception || "Chef client run completed in #{run_status.elapsed_time}"
      
      json = event.to_json
      logfile = File.open("/var/log/chef_handler_logstash.log", "w")
      logfile.puts "test line"
      logfile.puts json
      begin
        Timeout::timeout(@timeout) do
          
          ls = TCPSocket.new "#{@host}" , @port
          ls.puts json
          ls.close
        end
      rescue Exception => e
        Chef::Log.debug("Failed to write to #{@host} on port #{@port}: #{e.message}")
      end
    end
  end
end
