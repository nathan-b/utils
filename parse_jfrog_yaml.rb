#!/usr/bin/ruby

require 'yaml'

def get_package_name(path)
  path.split('/')[-1]
end

def get_cves(cves)
  l = []
  cves.each { |cve|
    l << cve['cve']
  }
  l.join(',')
end

h = YAML.load_file(ARGV.shift)

h[h.keys[0]].each { |rec|
  puts "[#{rec['severity']}] #{get_package_name(rec['impact_path'][0])} : #{get_cves(rec['cves'])}"
}

