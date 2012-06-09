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


# TODO: Add a timeout
#
class LogstashReporting < Chef::Handler
  attr_writer :tags, :host, :port

  def initialize(options = {})
    @tags = options[:tags] || Array.new
    @host = options[:host]
    @port = options[:port]
  end

  def report
    # A logstash json_event looks like this:
    # {
    #   "@source":"determined by logstash input def",
    #   "@type":"determined by logstash input def",
    #   "@tags":[],
    #   "@fields":{},
    #   "@timestamp":"ISO8601 of event",
    #   "@source_host":"host.foo.com",
    #   "@source_path":"typically the name of the log file",
    #   "@message":"escaped representation of event"
    # }
    #

    @updated_resources = []
    if run_status.updated_resources
      run_status.updated_resources.each {|r| @updated_resources << r.to_s }
    end
    event = Hash.new
    event["@source_host"] = run_status.node.name
    event["@tags"] = @tags
    event["@fields"] = Hash.new
    event["@fields"]["updated_resources"] = @updated_resources
    event["@fields"]["elapsed_time"] = run_status.elapsed_time
    event["@fields"]["success"] = run_status.success?
    # (TODO) Convert to ISO8601
    event["@fields"]["start_time"] = run_status.start_time
    event["@fields"]["end_time"] = run_status.end_time
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
    ls = TCPSocket.new "#{@host}" , @port
    begin
      ls.puts json
      ls.close
    rescue Exception => e
      Chef::Log.debug("Failed to write to #{@host} on port #{@port}: #{e.message}")
    end
  end
end
