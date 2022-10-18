#!/usr/bin/ruby

if ARGV.length == 0
  puts "I need a filename as an argument"
  return
end

def get_bucket(f)
  return 0 if (f == 0.0)

  if f < 25.0
    return 1
  elsif f < 35.0
    return 2
  elsif f < 50.0
    return 3
  elsif f < 75.0
    return 4
  elsif f < 95.0
    return 5
  else
    return 6
  end
end

def label(bucket)
  case bucket
  when 1
    return "< 25.0"
  when 2
    return "< 35.0"
  when 3
    return "< 50.0"
  when 4
    return "< 75.0"
  when 5
    return "< 95.0"
  when 6
    return "≥ 95.0"
  end
end

gbuckets = Hash.new(0)
nsamples = 0
drops = Hash.new()
while fname = ARGV.shift
  de = [0, 0]
  # Open and read the file
  ftext = File.read(fname)
  ftext.each_line { |line|
    if line =~ /c=([0-9.]+),/
      str_val = $1
      f = Float(str_val)
      bucket = get_bucket(f)
      next if bucket == 0
      nsamples += 1
      gbuckets[bucket] += 1
    end
    if line =~ / de=([0-9]+),/
      de[0] += 1.0
      de[1] += Float(Integer($1))
    end
  }
  drops.store(fname, de)
end

# Calculate percentage, then print scaled to 80%
puts "\nTotal counts\n================"
gbuckets.keys.sort.each {|k|
  pct = Float(gbuckets[k]) / Float(nsamples)
  puts "#{label(k)}: #{'*' * (pct * 80)}"
}

# Print drops
puts "\nAvg drops per sample:\n================"
drops.each { |k, v|
  puts "#{k}: #{v[1] / v[0]}"
}

