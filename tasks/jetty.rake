JETTY_CONFIG = {
    :jetty_home => File.expand_path("#{File.dirname(__FILE__)}/../jetty"),
    :jetty_port => "8983", :java_opts=>["-Xmx512m"],
    :startup_wait => 45
}
require 'jettywrapper'