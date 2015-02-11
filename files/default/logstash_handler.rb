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
    attr_writer :tags, :host, :port, :timeout, :type, :protocol, :application_name, :node_name, :run_list

    def initialize(options = {})
      Chef::Log.debug("initializing logstash handler")
      options[:tags] ||= Array.new
      options[:timeout] ||= 15
      @tags = options[:tags]
      @timeout = options[:timeout]
      @host = options[:host]
      @port = options[:port]
      @type = options[:type]
      @protocol = options[:protocol]
      @application_name = options[:application_name]
      @node_name = options[:node_name]
      @run_list = options[:run_list]
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
      Chef::Log.debug("generating report")
      event = Hash.new
      event["source"] = "chef://#{run_status.node.name}/handler/logstash"
      event["source_path"] = "#{__FILE__}"
      event["source_host"] = run_status.node.name
      event["tags"] = @tags
      event["fields"] = Hash.new
      event["fields"]["updated_resources"] = @updated_resources
      event["fields"]["elapsed_time"] = run_status.elapsed_time
      event["fields"]["success"] = run_status.success?
      # (TODO) Convert to ISO8601
      event["fields"]["start_time"] = run_status.start_time.to_time.iso8601
      event["fields"]["end_time"] = run_status.end_time.to_time.iso8601
      if run_status.backtrace
        event["fields"]["backtrace"] = run_status.backtrace.join("\n")
      else
        event["fields"]["backtrace"] = ""
      end
      if run_status.exception
        event["fields"]["exception"] = run_status.exception
      else
        event["fields"]["exception"] = ""
      end
      event["message"] = run_status.exception || "Chef client run completed in #{run_status.elapsed_time}"
      if @type
        event["type"] = @type
      end
      if @application_name
        event["application_name"] = @application_name
      end

      begin
        Chef::Log.debug("logging to #{@host} on port #{@port}")
        Timeout::timeout(@timeout) do
          json = event.to_json
          if @protocol == "tcp"
            ls = TCPSocket.new "#{@host}" , @port
            ls.puts json
          elsif @protocol == "udp"
            ls = UDPSocket.new
            ls.send(json, 0, @host, @port)
          else
            raise "protocol must be tcp or udp"
          end
          ls.close
        end
      rescue Exception => e
        Chef::Log.warn("Failed to write to #{@host} on port #{@port}: #{e.message}")
      end
    end
  end
end
