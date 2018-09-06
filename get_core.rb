#!/usr/bin/ruby

latest = `coredumpctl list | tail -n 1`
exe = latest.split('/')[-1].strip
pid = latest.match(/\s\d\d\d\d\d*\s/).to_s.strip

`sudo coredumpctl dump --output #{exe}.#{pid}.core`


