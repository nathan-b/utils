#include <thread>
#include "logger.h"
#include "utils.h"
#include "connection_manager.h"

#include <Poco/Foundation.h>
#include <Poco/Net/StreamSocket.h>
#include <Poco/Net/SecureStreamSocket.h>
#include <Poco/Net/SocketAddress.h>
#include <Poco/Net/InvalidCertificateHandler.h>
#include <Poco/Net/SSLException.h>
#include "async_stream_socket.h"

async_stream_socket::async_stream_socket(): StreamSocket(),
                                        m_connected(false)
{}

bool async_stream_socket::connect_async(const Poco::Net::SocketAddress& address,
                                        const Poco::Timespan& timeout,
                                        std::function<void(StreamSocket*, bool)> callback)
{
	thread t([this, &address, &timeout, &callback]
	{
		try
		{
			connect(address, timeout);
			m_connected = true;
		}
		catch(const Poco::IOException& e)
		{
			g_log->error("connectAsync():IOException: " + e.displayText());
		}
		catch(const Poco::TimeoutException& e)
		{
			g_log->error("connectAsync():Timeout: " + e.displayText());
		}

		callback(this, m_connected);
	});
	return true;
}

bool async_stream_socket::send_bytes_async(const void* buffer, int length, int flags, std::function<void(StreamSocket*, int)> callback)
{
	thread t([this, buffer, length, flags, &callback]
	{
		int result = 0;

		try
		{
			result = sendBytes(buffer, length, flags);
		}
		catch(const Poco::IOException& e)
		{
			g_log->error("sendBytesAsync():IOException: " + e.displayText());
			result = e.code();
		}
		catch(const Poco::TimeoutException& e)
		{
			g_log->error("sendBytesAsync():Timeout: " + e.displayText());
			result = -1;
		}

		if(callback)
		{
			callback(this, result);
		}
	});
	return true;
}

bool async_stream_socket::receive_bytes_async(void* buffer,
                                              int length,
                                              int flags,
                                              std::function<void(StreamSocket*, int, uint8_t*, uint32_t)> callback)
{
	if(!callback)
	{
		return false;
	}

	thread t([this, buffer, length, flags, &callback]
	{
		int result = 0;

		try
		{
			result = receiveBytes(buffer, length, flags);
			if (result == 0) {
				m_connected = false;
			}
		}
		catch(const Poco::IOException& e)
		{
			g_log->error("receiveBytesAsync():IOException: " + e.displayText());
			result = e.code();
		}
		catch(const Poco::TimeoutException& e)
		{
			g_log->error("receiveBytesAsync():Timeout: " + e.displayText());
			result = -1;
		}

		callback(this, result, (uint8_t*)buffer, result);
	});
	return true;
}

async_secure_stream_socket::async_secure_stream_socket(): SecureStreamSocket(),
                                                    m_connected(false)
{}

bool async_secure_stream_socket::connect_async(const Poco::Net::SocketAddress& address,
                                               const Poco::Timespan& timeout,
                                               std::function<void(StreamSocket*, bool)> callback)
{
	std::thread t([this, &address, &timeout, &callback]
	{
		try
		{
			setLazyHandshake(true);
			setPeerHostName(address.host().toString());
			connect(address, timeout);
			//
			// This is done to prevent getting stuck forever waiting during the handshake
			// if the server doesn't speak to us
			//
			setSendTimeout(connection_manager::SOCKET_TIMEOUT_DURING_CONNECT_US);
			setReceiveTimeout(connection_manager::SOCKET_TIMEOUT_DURING_CONNECT_US);

			int32_t ret = completeHandshake();

			if (ret == 1)
			{
				verifyPeerCertificate();
				g_log->information("SSL identity verified");
				m_connected = true;
			}
		}
		catch(Poco::IOException& e)
		{
			g_log->error("connectAsync():IOException: " + e.displayText());
		}
		catch(Poco::TimeoutException& e)
		{
			g_log->error("connectAsync():Timeout: " + e.displayText());
		}

		callback(this, m_connected);
	});
	return true;
}
