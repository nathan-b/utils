#!/usr/bin/ruby

disallow_exact_fit = true

l = ARGV.shift
byte_limit = 2000
if l
  byte_limit = Integer(l)
end

s = ""
c = 0
while s.length < byte_limit
  s << "dragent.bogus.test_stat#{c}:1|c\n"
  c += 1
  if disallow_exact_fit && s.length == byte_limit
    byte_limit += 1
  end
end

puts s

