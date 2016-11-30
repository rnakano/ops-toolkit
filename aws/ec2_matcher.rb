#!/usr/bin/env ruby

=begin
  usage: ./ec2_matcher.rb -s <INPUT_FORMAT> -d <OUTPUT_FORMAT> -p <AWS_PROFILE_NAME>

  Convert EC2 information

  example: echo 127.0.0.1 | ./ec2_matcher.rb -s PrivateIpAddress -d Name -p my-aws-profile  
=end

require 'optparse'
require 'json'

def ec2_instances(profile)
  instances = []
  json = `aws --profile #{ profile } ec2 describe-instances --filter "Name=instance-state-name,Values=running"`
  result = JSON.parse(json)
  result["Reservations"].each do |reservation|
    instances += reservation["Instances"]
  end
  instances
end

def find_instance(instances, value, format)
  instances.find do |instance|
    match?(instance, value, format)
  end
end

def match?(instance, value, format)
  elem = property(instance, format)
  return true if elem == value
  false
end

def print_instance(instance, format)
  puts property(instance, format)
end

def property(instance, format)
  if format == "Name"
    instance_name(instance)
  else
    instance[format]
  end
end

def instance_name(instance)
  instance["Tags"].each do |tag|
    return tag["Value"] if tag["Key"] == "Name"
  end
  return ""
end

params = ARGV.getopts("s:d:p:")

profile = params["p"]
src_format = params["s"] || "PublicIpAddress"
dst_format = params["d"] || "Name"

instances = ec2_instances(profile)

while line = ARGF.gets
  source = line.chomp
  instance = find_instance(instances, source, src_format)
  if instance
    print_instance(instance, dst_format)
  else
    puts "UNKOWN"
  end
end
