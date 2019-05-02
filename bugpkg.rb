#!/usr/bin/ruby

#
# Create directories for a specific bug and put relevant files there
#

require 'fileutils'

bug = 'new'
files = []

while a = ARGV.shift
  if a[0] == '-'
    case a[1..-1]
    when 'b'
      bug = ARGV.shift
      if bug =~ /^[0-9]/
        bug = "SMAGENT-" + bug
      end
    else
      puts "Unknown flag #{a}"
      exit -1
    end
  elsif File.exists?(a)
    files << a
  else
    puts "I don't know what to do with argument #{a}"
    exit -1
  end
end


bugdir = "/home/nathan/bugs/#{bug}"

`mkdir -p #{bugdir}`
files.each { |f|
  FileUtils.mv("#{Dir.getwd}/#{f}", "#{bugdir}/#{f}")
}

