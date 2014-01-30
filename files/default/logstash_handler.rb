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
require "time"


class Logstash < Chef::Handler
  attr_writer :metadata, :host, :port, :timeout

  def initialize(options = {})
    options[:tags] ||= Array.new
    options[:timeout] ||= 15
    @metadata = options[:metadata]
    @timeout = options[:timeout]
    @host = options[:host]
    @port = options[:port]
  end

  def report
    # A logstash v1 event looks like this:
    # {
    #   "@version":1,
    #   "@message":"escaped representation of event"
    # }
    #
    # The rest of the JSON can contain whatever is wanted but a good set of
    # basic fields to add are
    # "message" - The message you want to communicate
    # "source_host" - The originator of the message
    #
    # This handler will add those two fields along with some others with the chef run results

    @updated_resources = []
    if run_status.updated_resources
      run_status.updated_resources.each {|r| @updated_resources << r.to_s }
    end
    event = Hash.new
    event["@version"] = 1
    event["@timestamp"] = DateTime.now.iso8601
    event["source_host"] = run_status.node.name
    event["updated_resources"] = @updated_resources
    event["elapsed_time"] = run_status.elapsed_time
    event["success"] = run_status.success?
    event["start_time"] = run_status.start_time.to_time.iso8601
    event["end_time"] = run_status.end_time.to_time.iso8601
    if run_status.backtrace
      event["backtrace"] = run_status.backtrace.join("\n")
    end
    if run_status.exception
      event["exception"] = run_status.exception
    end
    event["message"] = run_status.exception || "Chef client run completed in #{run_status.elapsed_time}"
    if @metadata
      @metadata.each do |k,v|
        event[k] = v
      end
    end

    begin
      Timeout::timeout(@timeout) do
        json = event.to_json
        ls = TCPSocket.new "#{@host}" , @port
        ls.puts json
        ls.close
      end
    rescue Exception => e
      Chef::Log.debug("Failed to write to #{@host} on port #{@port}: #{e.message}")
    end
  end
end
