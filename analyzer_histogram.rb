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

# Open and read the file
ftext = File.read(ARGV.shift)
buckets = []
values = []
curr_bucket = 0
curr_bucket_desc = nil
ftext.each_line { |line|
  if line =~ /c=([0-9.]+),/
    str_val = $1
    f = Float(str_val)
    bucket = get_bucket(f)
    next if bucket == 0
    values << f
    if bucket == curr_bucket
      curr_bucket_desc[1] += 1
      curr_bucket_desc[2] = f if f > curr_bucket_desc[2]
    else
      buckets << curr_bucket_desc if curr_bucket_desc
      curr_bucket_desc = [bucket, 1, f]
      curr_bucket = bucket
    end
  elsif line =~ /Agent starting/
    buckets << [0] if buckets.count > 0
  end
}

buckets.each { |bdesc|
  if bdesc[0] == 0
    puts "--------------"
  else
    puts "#{'%-4d' % bdesc[1]} [#{'%6.2f' % bdesc[2]}]: #{'*' * bdesc[0]}"
  end
}

File.write("cpu.csv", values.join(','))

