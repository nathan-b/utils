#!/usr/bin/ruby

require 'socket'
require 'getoptlong'

def usage
  puts "Usage: send_udp [-a <host addr>] [-p <host port>] [-i <input file>]"
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--port', '-p', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--address', '--host', '-a', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--input', '-i', GetoptLong::REQUIRED_ARGUMENT ],
)

host = '127.0.0.1'
port = 8125
msg = ''

opts.each { |opt, arg|
  case opt
  when '--help'
    usage
    return 0
  when '--port'
    port = Integer(arg)
  when '--address'
    host = arg
  when '--input'
    msg = File.read(arg)
  end
}

sock = UDPSocket.new

if msg == ''
  ARGF.each_line { |line|
    msg << line
  }
end

sock.send(msg, 0, host, port)
sock.close

