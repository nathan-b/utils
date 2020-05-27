#!/usr/bin/ruby -w

require 'time'

# Sample lines:
# 2020-05-18 19:19:45.420, 3656559.3656614, Information, connection_manager:1534: Sent msgtype=3 len=6859 to collector
# 2020-05-18 19:19:45.420, 3656559.3656614, Information, connection_manager:1540: 	Generation: 1  Sequence: 1
# 2020-05-18 19:19:45.420, 3656559.3656614, Information, connection_manager:1825: Received command 16 (ORCHESTRATOR_EVENTS)
# 2020-05-18 19:19:45.420, 3656559.3656614, Information, connection_manager:1835:     header_len: 22    length field: 42    version field: 5
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1513: Sending header length 22
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1393: Sending 22 bytes
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1523: Sending buffer length 6413
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1393: Sending 6413 bytes
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1534: Sent msgtype=3 len=6435 to collector
# 2020-05-18 19:19:45.421, 3656559.3656614, Information, connection_manager:1540: 	Generation: 1  Sequence: 1

curr_pid = 0
curr_gen = 0
run_start = nil
run_end = nil
version = ''
cmds = []

restarts = 0

curr_cmd = {}

# Handle ^C
Signal.trap("INT") {
  puts_finished_run(perf_msgs, critical_msgs, restarts)
  exit
}

# Read from file or pipe
ARGF.each_line { |line|
  larr = line.split(', ')
  line.strip!

  # Catch non-log output (i.e. lines without a log header)
  if larr.length < 4 
    next
  end

  msg = larr[3].split(':')

  # Detect pid change
  begin
    pid = Integer(larr[1].split('.')[0])
  rescue ArgumentError
    next
  end
  if (pid != curr_pid) && (curr_pid != 0)
    puts "New pid found (#{curr_pid} => #{pid}), agent restarted!"
    restarts += 1
  end
  curr_pid = pid

  # Detect generation change
  if msg[2] =~ /Generation: (\d+)/ 
    if curr_gen != 0
      puts "New generation number found (#{curr_gen} => #{$1}"
    end
    curr_gen = Integer($1)
  end

  # Look for lines containing messages we know to be important
  t = 0
  begin
    t = Time.parse(larr[0])
    run_end = t
  rescue
    puts "Couldn't parse timestamp #{larr[0]}"
  end

  if msg[2] =~ /Agent starting \(version (.*)\)/
    run_start = Time.parse(larr[0])
    version = $1
  elsif (msg[2] =~ /Sending buffer length /)
    curr_cmd[:start_time] = t
    curr_cmd[:direction] = :out
  elsif msg[2] =~ /Sent msgtype=(\d+) len=(\d+) to collector/
    curr_cmd[:type] = $1
    curr_cmd[:len] = $2
    curr_cmd[:send_time] = t
    if (!curr_cmd[:direction] || curr_cmd[:direction] != :out)
      puts "Found orphaned sent command"
    else
      cmds << curr_cmd
    end
    curr_cmd = {}
  elsif msg[2] =~ /Received command (\d+) \((.*)\)/
    incmd = {}
    incmd[:direction] = :in
    incmd[:type] = $1
    incmd[:name] = $2
    incmd[:recv_time] = t
    cmds << incmd
  end
}

def get_bucket(timediff)
  if timediff < 0.01
    return 1
  elsif timediff < 0.1
    return 2
  elsif timediff < 0.5
    return 3
  elsif timediff < 1
    return 4
  elsif timediff < 5
    return 5
  elsif timediff < 10
    return 6
  elsif timediff < 20
    return 7
  end
  return 8
end



puts "\n=========================================\n"
if run_start
  puts "Run starting at #{run_start} took #{run_end - run_start} seconds, agent version #{version}"
end

out_histo = Hash.new(0)
in_histo = Hash.new(0)
delay_histo = Hash.new(0)
cmds.each { |cmd|
  if cmd[:direction] == :out
    diff = 0
    if cmd[:send_time]
      diff = cmd[:send_time] - cmd[:start_time]
    else
      puts "No corresponding send!"
    end
    delay_histo[get_bucket(diff)] += 1
    out_histo[cmd[:type]] += 1
    if get_bucket(diff) > 4
      puts ">OUT> #{cmd[:send_time]} - Long-running command of type #{cmd[:type]} (#{cmd[:len]} bytes, #{diff} seconds)"
    end
  else
    puts "<IN<< #{cmd[:recv_time]} - #{cmd[:type]} (#{cmd[:name]})"
    in_histo[cmd[:type]] += 1
  end
}

puts "\n=========================================\n"
puts "Delay histogram"
puts "<.01s: #{delay_histo[1]}"
puts "<.05s: #{delay_histo[2]}"
puts "<1s  : #{delay_histo[3]}"
puts "<5s  : #{delay_histo[4]}"
puts "<10s : #{delay_histo[5]}"
puts "<20s : #{delay_histo[6]}"
puts ">=20s: #{delay_histo[7]}"


puts "\n=========================================\n"
puts "Message out histogram"
out_histo.each { |k, v|
  puts "#{`msgtype #{k}`.strip}: #{v}"
}

puts "\n=========================================\n"
puts "Message in histogram"
in_histo.each { |k, v|
  puts "#{`msgtype #{k}`.strip}: #{v}"
}

