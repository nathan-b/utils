#!/usr/bin/ruby

require 'date'

h = {}

ARGV.each { |f|
  ft = File.read(f)
  ts = DateTime.parse(ft[0..24])
  h.store(ts, ft)
}

h.keys.sort.each { |k|
  puts h[k]
}

