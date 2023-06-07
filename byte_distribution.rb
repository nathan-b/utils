#!/usr/bin/ruby

def percent_string(val, total)
  return "#{(Float(val) / Float(total) * 100.0).round(2)}%"
end

# Read in the whole file
ftext = ''
File.open(ARGV.shift, 'rb') { |f|
  ftext = f.read()
}

# Set up the collection data structures
stats = Hash.new(0)
bytes = []
total_bytes = 0
0.upto(0xff) { |n| bytes[n] = [0, n] }

# Scan the whole file
ftext.each_byte { |c|
  bytes[c][0] += 1
  total_bytes += 1
}

# Print the results
stats[:zero] = bytes[0][0]
bytes.sort!.reverse!
bytes.each_index { |idx|
  next if bytes[idx][0] == 0
  str = "#{bytes[idx][1].to_s(16).rjust(2)} "
  if bytes[idx][1].chr =~ /[[:print:]]/
    stats[:printable] += bytes[idx][0]
    str << "(#{bytes[idx][1].chr})"
  else
    str << "   "
  end
  str << ": #{bytes[idx][0].to_s.rjust(5)}  (#{percent_string(bytes[idx][0], total_bytes)} of total)"
  puts str
}
puts "#{percent_string(stats[:printable], total_bytes)} printable"
puts "#{percent_string(stats[:zero], total_bytes)} zero"

