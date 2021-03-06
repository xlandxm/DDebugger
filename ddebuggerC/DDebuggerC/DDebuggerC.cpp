
#include <iostream>
#include <WinSock2.h>
#include <thread>
#include <string>
#include <ctime>  
#include "dsocket.h"

SOCKET clientsocket = INVALID_SOCKET;
time_t tAlive = 0;

void HearBeatThreadFunc()
{
	while (clientsocket != INVALID_SOCKET)
	{
		time_t nowTime = time(NULL);
		if (tAlive > 0 && (nowTime - tAlive) > 5)
		{
			DDebugger::SendPacket(clientsocket, "Keep", 5);
			tAlive = nowTime;
		}
	}
}

void RecvThreadFunc()
{
	char recvBuf[MAX_MESSAGE_LENTH];
	while (clientsocket != INVALID_SOCKET)
	{
		memset(recvBuf, 0, sizeof(recvBuf));
		if (recv(clientsocket, recvBuf, MAX_MESSAGE_LENTH, 0) > 0)
		{
			tAlive = time(NULL);
			std::cerr << recvBuf << std::endl;
		}
	}
}

void SendThreadFunc()
{
	while (clientsocket != INVALID_SOCKET)
	{
		std::string command;
		std::getline(std::cin, command);
		command += '\n';
		DDebugger::SendPacket(clientsocket, command.data(), (int)command.size());
	}
}

void main()
{

	DDebugger::InitSocketLib();
	
	
	if (!DDebugger::InitClientSocket(clientsocket))
	{
		return;
	}

	std::thread recv_thread(RecvThreadFunc);
	std::thread send_thread(SendThreadFunc);

	recv_thread.join();
	send_thread.join();

	system("pause");		
}

