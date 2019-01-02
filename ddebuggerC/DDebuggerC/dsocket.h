#ifndef __DSOCKET_H__
#define __DSOCKET_H__

#include <WinSock2.h>


#define CONNECT_NUM_MAX 1
#define MAX_MESSAGE_LENTH 1024

namespace DDebugger
{
	bool InitSocketLib();

	bool CreateSocket(SOCKET &serverSocket);
	bool ListenSocket(SOCKET &serverSocket);
	
	void SendPacket(const SOCKET &socket, const char* data, int length);
	void CloseSocket(SOCKET &socket);


	bool InitClientSocket(SOCKET &clientsocket);
}

#endif 

