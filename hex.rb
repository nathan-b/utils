#!/usr/bin/ruby

while (i = ARGV.shift)
	if i[0..1] == '0x'
		puts "#{i} => #{i[2..-1].to_i(16)}"
	else
		puts "#{i} => 0x#{i.to_i.to_s(16)}"
	end
end

