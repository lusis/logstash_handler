name             "logstash_handler"
maintainer       "John E. Vincent"
maintainer_email "lusis.org+github.com@gmail.com"
license          "Apache 2.0"
description      "Installs/Configures a Chef handler for dumping to Logstash over a TCP or UDP input"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.2"

depends "chef_handler"
