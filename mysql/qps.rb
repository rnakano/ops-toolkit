#!/usr/bin/env ruby

=begin
  usage: ./qps.rb -h <MYSQL_HOST> -u <MYSQL_USER> -p <MYSQL_PASSWORD> -i <INTERVAL>

  Show MySQL qps
=end

def mysql_connect_command(user, password, host)
  if password.empty?
    "mysql -u #{ user } -h #{ host }"
  else
    "mysql -u #{ user } -p'#{ password }' -h #{ host }"
  end
end

def query_count(host, user, password)
  stacked_query_count = Hash.new(0)
  status_lines = `#{ mysql_connect_command(user, password, host) } -e "SHOW GLOBAL STATUS" -N 2> /dev/null`.each_line.to_a
  status_lines.select do |line|
    line =~ /Com_(insert|select|update|delete|commit)/
  end.each do |line|
    name, count = line.split(/\s+/)
    stacked_query_count[name.sub("Com_", "")] = count.to_i
  end
  stacked_query_count
end

def query_per_second(prev, now, interval)
  qps = Hash.new(0)
  now.each do |name, count|
    step = count - prev[name]
    qps[name] = (step / interval).to_i
  end
  qps
end

def display(qps)
  qps.each do |name, count|
    print "#{ name }:#{ count }\t"
  end
  puts ""
end

require 'optparse'

params = ARGV.getopts("h:u:p:i:")

host = params["h"] || "localhost"
user = params["u"] || "root"
password = params["p"] || ""
interval = (params["i"] || 2).to_i

prev_count = Hash.new(0)

while true
  now_count = query_count(host, user, password)
  qps = query_per_second(prev_count, now_count, interval)
  display(qps)
  prev_count = now_count
  sleep interval
end
