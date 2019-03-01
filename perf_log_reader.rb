#!/usr/bin/ruby -w

# Sample lines:
# 2019-02-28 19:46:55.987, 12016, Information, sinsp_data_handler:63: ts=1551383214, len=8664, ne=1461322, de=5809259, c=94.95, fp=0.03, sr=8, st=0, fl=24
# watchdog: too many tid collisions
# 2019-02-28 19:57:15.694, 5882, Error, 02-28 19:57:15.694072 sinsp Reached maximum sampling ratio and still too high
# 2019-02-28 19:57:11.521, 5882, Information, 02-28 19:57:11.521434 Top calls while sampling (34354 total), openat(306):17838, close(4):16413, clone(222):40, dup(124):30, prlimit(144):10
# watchdog: committing suicide
# 

PRINT_THRESHHOLD = 100

curr_pid = 0
watchdog_msgs = []
perf_msgs = []
rolling_perf_msgs = []
critical_msgs = []

restarts = 0
loops = 0

#
# Add stats to a rolling list of stats messages, dropping old messages if necessary
#
def add_to_rolling_list(rolling_perf_msgs, msg)
  rolling_perf_msgs.push(msg)

  while rolling_perf_msgs.length > PRINT_THRESHHOLD
    rolling_perf_msgs.delete_at(0)
  end
end

#
# Parse a log line and build a perf message object
#
def build_perf_msg(line)
  if match = line.match(/len=(\d+), ne=(\d+), de=(\d+), c=([-0-9.]+), fp=([0-9.]+), sr=(\d+), st=(\d+), fl=(\d+)/)
    len, ne, de, c, fp, sr, st, fl = match.captures
    return {} if Float(c) < 0 # CPU% can be -1.00 sometimes, for some reason. Reject these lines.
    return {
      :len => Integer(len),
      :ne => Integer(ne),
      :de => Integer(de),
      :c => Float(c),
      :fp => Float(fp),
      :sr => Integer(sr),
      :st => Integer(st),
      :fl => Integer(fl)
    }
  end
  puts "Bogus line #{line}"
  return {}
end

#
# Convert a perf message object to a string.
#
def print_perf_msg(msg)
  s = ""
  msg.each { |k, v|
    s << "#{k}=#{Float(v).round(2)} "
  }
  return s
end

#
# Compute arithmatic mean of all stats in the message list. Returns 
# a perf message object containing the average.
#
def get_avg_perf(perf_msgs)
  total = Hash.new(0)
  avg = {}

  return total if perf_msgs.length == 0

  # First sum up all the stats in all the messages
  perf_msgs.each { |msg|
    msg.each { |k, v|
      total[k] += v
    }
  }

  # Now calculate the average
  total.each { |k, v|
    avg.store(k, Float(v) / Float(perf_msgs.length))
  }
  return avg
end

#
# Build a string containing the summary line written every few messages.
#
def print_summary(perf_msgs, critical_msgs, restarts)
  s = ""
  avg = get_avg_perf(perf_msgs)

  s << print_perf_msg(avg)
  s << "\n"
  s << "Agent restarted #{restarts} times\n"
end

#
# At the end of a run, print a summary of the gathered data.
#
def puts_finished_run(perf_msgs, critical_msgs, restarts)
  puts "RUN COMPLETE"
  puts print_summary(perf_msgs, critical_msgs, restarts)
  if critical_msgs.length > 0
    puts "Critical messages\n"
    puts "=================\n"
    critical_msgs.each { |msg|
      puts msg
    }
  end
end

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
  if larr.length < 3 
    if line.start_with?('watchdog')
      watchdog_msgs << line.split(': ')[1]
    end
    next
  end

  # Detect pid change
  begin
    pid = Integer(larr[1])
  rescue ArgumentError
    next
  end
  if (pid != curr_pid) && (curr_pid != 0)
    puts "New pid found (#{curr_pid} => #{pid}), agent restarted!"
    restarts += 1
  end
  curr_pid = pid

  # Look for perf lines
  if (line =~ /sinsp_data_handler/) && larr.length == 12
    msg = build_perf_msg(line)
    perf_msgs << msg
    add_to_rolling_list(rolling_perf_msgs, msg)
  end

  # Look for lines containing messages we know to be important
  if (line =~ /Reached maximum sampling ratio and still too high/)
    critical_msgs << line
  end

  loops += 1
  if (loops % PRINT_THRESHHOLD == 0)
    puts print_summary(rolling_perf_msgs, critical_msgs, restarts)
  end
}

puts_finished_run(perf_msgs, critical_msgs, restarts)

