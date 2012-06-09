Description
===========

A cookbook for a `chef_handler` that sends reports and exceptions to Logstash over a TCP input in native `json_event` format

Requirements
============

The `chef_handler` cookbook.

Attributes
==========

This cookbook uses the following attributes to configure how it is installed.

* `node['chef_client']['handler']['logstash']['host']` - The logstash server host.
* `node['chef_client']['handler']['logstash']['port']` - The logstash server port.

Optional attribute

* `node['chef_client']['handler']['logstash']['tags']` - Any additional tags you want sent along with the event. This can save on filter usage down the pipeline

Usage
=====

Set the host and port properties on the node/environment and include the `logstash_handler` recipe.

On your logstash side, you'll need to create a TCP input like so:

```
input {
  tcp {
    type => "chef_handler"
    format => "json_event"
    port => "5959"
  }
}
```

You can inspect the source for details on what the generated event looks like.

**PLEASE NOTE**
The changes neccessary to the `json_event` format in Logstash are only available in master.

Credits
=======

Borrowed quite a bit from the `graphite_handler` cookbook [here](https://github.com/realityforge-cookbooks/graphite_handler)
