#include "dsocket.h"

#include <iostream>
#include <WinSock2.h>

#pragma comment(lib, "ws2_32.lib")


bool DDebugger::InitSocketLib()
{
	//加载套接字库
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
	{
		std::cout << "WSAStartup(MAKEWORD(2, 2), &wsaData) execute failed!" << std::endl;
		return false;
	}
	if (2 != LOBYTE(wsaData.wVersion) || 2 != HIBYTE(wsaData.wVersion))
	{
		WSACleanup();
		std::cout << "WSADATA version is not correct!" << std::endl;
		return false;
	}
	return true;
}


bool DDebugger::CreateSocket(SOCKET &serverSocket)
{
	//创建套接字
	serverSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (serverSocket == INVALID_SOCKET)
	{
		std::cout << "serverSocket = socket(AF_INET, SOCK_STREAM, 0) execute failed!" << std::endl;
		return false;
	}

	//初始化服务器地址族变量
	SOCKADDR_IN addrSrv;
	addrSrv.sin_addr.S_un.S_addr = htonl(INADDR_ANY);
	addrSrv.sin_family = AF_INET;
	addrSrv.sin_port = htons(6000);

	//绑定
	if (bind(serverSocket, (SOCKADDR*)&addrSrv, sizeof(SOCKADDR)) == SOCKET_ERROR)
	{
		std::cout << "bind(serverSocket, (SOCKADDR*)&addrSrv, sizeof(SOCKADDR)) execute failed!" << std::endl;
		return false;
	}
	return true;
}

bool DDebugger::ListenSocket(SOCKET &serverSocket)
{
	if (serverSocket == INVALID_SOCKET)
	{
		return false;
	}
	if (listen(serverSocket, CONNECT_NUM_MAX) == SOCKET_ERROR)
	{
		std::cout << "listen(serverSocket, 10) execute failed!" << std::endl;
		return false;
	}
	return true;
}

void DDebugger::SendPacket(const SOCKET &socket, const char* data, int length)
{
	if (socket == INVALID_SOCKET)
	{
		return ;
	}
	if (data == NULL)
	{
		return ;
	}
	if (length < 0 || length >= MAX_MESSAGE_LENTH)
	{
		return ;
	}
	send(socket, data, length, 0);
}

void DDebugger::CloseSocket(SOCKET &socket)
{
	if (socket == INVALID_SOCKET)
	{
		return;
	}
	closesocket(socket);
}

bool DDebugger::InitClientSocket(SOCKET &clientsocket)
{
	//创建套接字 
	if((clientsocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) <= 0) 
	{ 
		printf("套接字socket创建失败!\n"); 
		return false; 
	} 

	SOCKADDR_IN serveraddr;
	serveraddr.sin_family = AF_INET; 
	serveraddr.sin_port = htons(6000); 
	serveraddr.sin_addr.S_un.S_addr = inet_addr("127.0.0.1");

	//请求连接 
	printf("尝试连接中...\n"); 
	if(connect(clientsocket, (SOCKADDR *)&serveraddr, sizeof(serveraddr)) != 0) 
	{ 
		printf("连接失败!\n"); 
		return false; 
	} 
	printf("连接成功!\n");
	return true;
}