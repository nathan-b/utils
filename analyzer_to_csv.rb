#!/usr/bin/ruby

fields = ['ne', 'de', 'c', 'fp', 'sr', 'st', 'fl', 'lat']

flushes = []
while fname = ARGV.shift
  de = [0, 0]
  # Open and read the file
  ftext = File.read(fname)
  ftext.each_line { |line|
    if md = line.match(/ne=(\d+), de=(\d+), c=([0-9.]+), fp=([0-9.]+), sr=(\d+), st=(\d+), fl=(\d+), lat=([0-9.]+)/)
      flushes << {'ne' => md[1].to_i, 'de' => md[2].to_i, 'c' => md[3].to_f, 'fp' => md[4].to_f, 'sr' => md[5].to_i, 'st' => md[6].to_i, 'fl' => md[7].to_i, 'lat' => md[8].to_f}
    end
  }
end

puts fields.join(',') # Write the header
# Write the values
flushes.each { |flush|
  vals = []
  fields.each { |f|
    vals << flush[f]
  }
  puts vals.join(',')
}
