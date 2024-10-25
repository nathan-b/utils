#!/usr/bin/ruby

p = :char
while (c = ARGV.shift)
  if c == '-c'
    print = :char
    c = ARGV.shift
  elsif c == '-a'
    print = :val
    c = ARGV.shift
  elsif c == '-x'
    print = :hex
    c = ARGV.shift
  elsif c == '-d'
    print = :dec
    c = ARGV.shift
  elsif c =~ /^[0-9]+$/
    print = :char
  else
    print = :val
  end

  if print == :char
    puts Integer(c).chr
  elsif print == :val
    puts "#{c.ord} (#{c.ord.to_s(16)})"
  elsif print == :dec
    puts c.ord
  elsif print == :hex
    puts c.ord.to_s(16)
  end
end

