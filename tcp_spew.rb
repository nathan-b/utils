#!/usr/bin/ruby

require 'socket'

$server = 'localhost'
$port = 7357

$threads = 3

def get_random_string(len)
 return  ('a'..'z').to_a.shuffle[0, len].join
end

def spew_bytes(socket)
  s = get_random_string(4096)
  while(true)
    socket.puts(s)
  end
end

tlist = []

$threads.times {
  tlist << Thread.new {
    spew_bytes(TCPSocket.open($server, $port))
  }
}

tlist.each { |t| t.join }

