#!/usr/bin/ruby

require 'date'

def diff_in_seconds(newer, older)
  return ((newer - older) * (24 * 60 * 60)).to_f
end

show_logsites = false
files = []

# Parse options
while o = ARGV.shift
  if o[0] == '-'
    case o
    when '-l'
      show_logsites = true
    else
      puts "Unrecognized option #{o}"
    end
  else
    files << o
  end
end

while fname = files.shift
  # Open and read the file
  ftext = File.read(fname)
  last = nil
  last_ts = nil
  logsites = Hash.new(0)
  normal_logsites = Hash.new(0)
  normal_seconds = 0
  ep_thread = 0
  ftext.each_line { |line|
    larr = line.split(',')
    if line =~ /ne=(\d+), de=(\d+), c=([0-9.]+),/
      ts = larr[0]
      ep_thread = larr[1]
      if last == nil
        last = DateTime.parse(ts) 
      else
        now = DateTime.parse(ts)
        diff = diff_in_seconds(now, last)
        if diff > 2
          puts "Flush at #{ts} is delayed by #{diff} seconds from previous flush at #{last_ts}"
          if show_logsites
            logsites.each { |k, v|
              puts "\t#{k} => #{v} (#{(v.to_f / diff).round(1)} per sec)" if v > 10
            }
          end
        else # Not a delayed flush
          if show_logsites
            logsites.each { |k, v|
              normal_logsites[k] += v
            }
            normal_seconds += diff
          end
        end
        last = now
      end
      last_ts = ts
      logsites = Hash.new(0)
    else
      # Get the log site
      next if (!larr[3]) || !(larr[0] =~ /^20/) || larr[1] != ep_thread
      site = larr[3].split(' ')[0].split(':')[0]
      logsites[site] += 1
    end
  }

  if show_logsites
    puts "Normal log site distribution (#{normal_logsites.length} data points}"
    normal_logsites.each { |k, v|
      per_sec = v.to_f / normal_seconds
      if per_sec > 0.5
        puts "\t#{k} => #{v} (#{per_sec.round(1)} per second)"
      end
    }
  end
end


