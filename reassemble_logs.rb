#!/usr/bin/ruby

require 'date'

h = {}

ARGV.each { |f|
  ft = File.read(f)
  ts = nil
  begin
    ts = DateTime.parse(ft[0..24])
    h.store(ts, ft)
  rescue
    STDERR.puts "Could not parse #{ft[0..24]} for file #{f}, skipping"
  end
}

h.keys.sort.each { |k|
  puts h[k]
}

