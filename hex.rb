#!/usr/bin/ruby

while (i = ARGV.shift)
	puts "#{i} => 0x#{i.to_i.to_s(16)}"
end

