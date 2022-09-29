#!/usr/bin/ruby

def is_reconn?(rc)
  return " (reconnect!)" if rc
  return ""
end

while f = ARGV.shift
  fstr = File.read(f)
  num_metrics = 0
  reconn = true

  fstr.each_line { |l|
    if l =~ /analyzer:\d+:\s*ts=/
      num_metrics += 1
    end
    if l =~ /Sent msgtype=1 /
      if num_metrics != 10
        larr = l.split(' ')
        puts "Expected 10 metrics, saw #{num_metrics} at #{larr[0]} #{larr[1]} #{is_reconn?(reconn)}"
      end
      num_metrics = 0
    end
    if l =~ /Connected to collector/
      num_metrics = 0
      reconn = true
    end
  }
end

