#!/usr/bin/ruby

require 'digest/md5'

logt = File.read(ARGV.shift)

policies = {}
policy_times = Hash.new { |h, k| h[k] = [] }
policy = ''
in_policy = true
policy_time = ''
policy_digest = ''
logt.each_line { |line|
  if in_policy
    if line.strip.empty?
      policy << line
      in_policy = false
      digest = policy_digest
      policies[digest] = policy
      policy_times[digest] << policy_time
    else
      policy << line
    end
  elsif line =~ /policy_list {/
    policy = "policy_list {\n"
    in_policy = true
    policy_time = line.split(',')[0]
  elsif line =~ /registering policies; digests old: (\w*), new: (\w+)/
    puts "#{line.split(',')[0]}: #{$1} => #{$2}"
    policy_digest = $2
  end
}

policies.each { |k, v|
  next if k.empty?
  File.write("#{k}.json", v)
  puts "I have a policy with digest #{k} at time #{policy_times[k]} (wrote #{k}.json)"
}

