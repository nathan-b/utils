#pragma once

#include <Poco/Foundation.h>
#include <Poco/Net/StreamSocket.h>
#include <Poco/Net/SecureStreamSocket.h>
#include <Poco/Net/SocketAddress.h>

#include <thread>
#include "connection_manager.h"

// If I were smarter I could figure out how to make these classes inherit from
// each other to avoid code duplication, but the SecureStreamSocket and the
// StreamSocket seem to use a different backend (SecureStreamSocketImpl uses
// OpenSSL and StreamSocketImpl / SocketImpl uses BSD sockets).

/// Adds async methods to the StreamSocket
class async_stream_socket : public Poco::Net::StreamSocket
{
public:
	async_stream_socket();

	bool connect_async(const Poco::Net::SocketAddress& address,
	                   const Poco::Timespan& timeout,
	                   std::function<void(StreamSocket*, bool)> callback);

	bool is_connect_complete() const { return m_connected; }

	bool send_bytes_async(const void* buffer,
	                      int length,
	                      int flags,
	                      std::function<void(StreamSocket*, int)> callback);

	bool receive_bytes_async(void* buffer,
	                         int length,
	                         int flags,
	                         std::function<void(StreamSocket*, int, uint8_t*, uint32_t)> callback);
private:
	bool m_connected;
};

///  Adds async methods to the SecureStreamSocket
/// Only provides async connection right now to avoid code duplication
class async_secure_stream_socket : public Poco::Net::SecureStreamSocket
{
public:
	async_secure_stream_socket();

	bool connect_async(const Poco::Net::SocketAddress& address,
	                   const Poco::Timespan& timeout,
	                   std::function<void(StreamSocket*, bool)> callback);

	bool is_connect_complete() const { return m_connected; }

private:
	bool m_connected;
};

