#!/usr/bin/ruby

def load_values(path)
  s = File.read(path)
  
  messages = s.split("enum message_type")[1].split('}')[0]

  m = {}
  messages.scan(/(\S+) = (\d+)/) { |name, val| 
    m.store(val, name)
    m.store(Integer(val), name)
  }
  return m
end

$msg_map = load_values("/home/nathan/src/draios/protorepo/agent-be/proto/draios.proto")
while a = ARGV.shift
  puts $msg_map[a]
end

