#!/usr/bin/ruby

require 'thread'
require 'socket'

$threads = 100
$server = 'localhost'
$port = 7357

s = ARGV.shift
$server = s if s

p = ARGV.shift
$port = p.to_i if p && (p.to_i > 0)

thread_list = []

$threads.times {
  thread_list << Thread.new {
    while true
      sock = TCPSocket.open($server, $port)

      sock.puts("Hi")

      sock.close
      sleep 0.1
    end
  }
}

thread_list.each { |t|
  t.join()
}

