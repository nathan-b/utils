#!/usr/bin/ruby

require 'json'

Tag = 0
CVE = 1
Sev = 2
Pkg = 3
Fix = 4
URL = 5

def fix_url(url)
  url =~ />(.+)</
  $1
end

cves = {}
ignore_sevs = {'Low' => 1, 'Medium' => 1}

vulns = JSON.parse(ARGF.read)

vulns['data'].each { |vuln|
  next if ignore_sevs.has_key?(vuln[Sev])
  next if cves.has_key?(vuln[CVE])

  cves.store(vuln[CVE], vuln)
}

cves.each { |cve, vuln|
  puts "#{cve.ljust(24)}\t#{vuln[Sev].ljust(8)}\t#{vuln[Pkg].ljust(42)}\tFix: #{vuln[Fix].ljust(32)}\t#{fix_url(vuln[URL])}"
}


