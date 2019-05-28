#!/usr/bin/ruby

#
# Create directories for a specific bug and put relevant files there
#

require 'fileutils'

def try_untar(f)
  res = `tar tf #{f} 2>&1`.split("\n")
  if !$?.success?
    # OK, guess it's not a tar archive
    return false
  end

  # For now just untar into current directory
  `tar xf #{f}`
  return $?.success?
end

def try_unzip(f)
  res = `file -b #{f}`.split(' ')
  case res[0]
  when 'gzip'
    `gunzip #{f}`
  when 'bzip2'
    `bunzip2 #{f}`
  when 'Zip'
    `unzip #{f}`
  when '7-zip'
    `7z e #{f}`
  end
  return $?.success?
end

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

# Copy files to the bug dir
files.each { |f|
  FileUtils.mv("#{Dir.getwd}/#{f}", "#{bugdir}/#{f}")
}

# Post-process files
Dir.chdir(bugdir)
files.each { |f|
  next if try_untar(f)
  next if try_unzip(f)
}

