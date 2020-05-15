#!/usr/bin/ruby

require 'thread'
require 'socket'

$BUFSIZE = 4096
$DEFAULT_PORT = 7357

def cputs(string, id = '')
  puts "#{id} >> #{string}"
end

def handle_client(socket, cname)
  begin
    connected = true
    data = ''
    while connected
      indata = socket.recv($BUFSIZE)
      if indata == ''
        connected = false
        next
      end
    end

    cputs("Disconnected", cname)
  rescue Errno::ECONNRESET, Errno::EPIPE
    cputs("Unexpected termination", cname)
  end

  socket.close
end

def run_server(port)
  socket = Socket.new(:INET, :SOCK_STREAM)
  socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
  socket.bind(Addrinfo.tcp('0.0.0.0', port))
  socket.listen(1)
  cputs("Waiting for connections on port #{port}", 'server')
  return socket
end

def get_port()
  return $DEFAULT_PORT if ARGV.length == 0
  return Integer(ARGV.shift)
end

ssock = run_server(get_port)
tlist = []
while true
  csock, ainfo = ssock.accept
  cname = ainfo.getnameinfo()[0]
  cputs("Incoming connection from #{cname}", 'server')
  tlist << Thread.new(csock, cname) { |csock, cname|
    handle_client(csock, cname) 
  }
end

