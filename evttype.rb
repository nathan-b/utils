#!/usr/bin/ruby

def populate_types(filename)
  s = File.read(filename)
  h = {}
  i = 0
  s.each_line { |line|
    next if !line.strip.start_with?('/* PPME_')
    direction = ''
    if line =~ /(\w) \*\//
      direction = $1
    end
    name = 'unknown'
    if line =~ /\/{"([^"]+)",/
      name = $1
    end
    h.store(i, name + direction)
    i += 1
  }
  return h
end

types = populate_types("/home/nathan/src/draios/agent-libs/driver/event_table.c")

while (et = ARGV.shift)
  puts types[Integer(et)]
end

