#define _CRT_SECURE_NO_WARNINGS

#include <iostream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h> 

#define MAX_BUFFER_SIZE 1024*8// 8kb
#define PORT_LISTENING 50000
#define PORT_RECEIVER 60000

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "ERROR: wrong number of arguments" << std::endl;
        std::cout << "Runtime example: ./a.out 127.0.0.1" << std::endl;
        return EXIT_FAILURE;
    }
    std::string receiver_address = argv[1];
    
    /*establish structure*/
    int receive_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (receive_socket < 0) {
        std::cerr << "ERROR: socket() failed" << std::endl;
        return EXIT_FAILURE;
    }
    int send_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (send_socket < 0) {
        std::cerr << "ERROR: socket() failed" << std::endl;
        return EXIT_FAILURE;
    }
    
    struct sockaddr_in udp_server, udp_client, udp_receiver;
	memset(&udp_server, 0, sizeof(udp_server));
	memset(&udp_client, 0, sizeof(udp_client));
    memset(&udp_receiver, 0, sizeof(udp_receiver));
    
    struct hostent* receiver = gethostbyname(receiver_address.c_str());
    if (receiver == NULL) {
        std::cerr << "ERROR: gethostbyname() failed" << std::endl;
        std::cerr << "invalid receiver address" << std::endl;
        return EXIT_FAILURE;
    }
    
    udp_server.sin_family = AF_INET;
    udp_server.sin_addr.s_addr = htonl(INADDR_ANY);
    udp_server.sin_port = htons(PORT_LISTENING);
    
    udp_receiver.sin_family = AF_INET;
    memcpy(&udp_receiver.sin_addr.s_addr,receiver->h_addr,receiver->h_length);
    udp_receiver.sin_port = htons(PORT_RECEIVER);
    
    if (bind(receive_socket, (struct sockaddr*) &udp_server, sizeof(udp_server)) < 0) {
        std::cerr << "ERROR: bind() failed" << std::endl;
        return EXIT_FAILURE;
    }

    unsigned int sizeOfSockaddr = sizeof(udp_server);

    if(getsockname(receive_socket, (struct sockaddr *) &udp_server, &sizeOfSockaddr)<0) {
        std::cerr << "ERROR: getsockname() failed" << std::endl;
        return EXIT_FAILURE;
    }
    std::cout << "Listening for UDP connections on port: " << ntohs(udp_server.sin_port) << std::endl;
    std::cout << "Redirecting datagram to " << receiver_address << " on port " << PORT_RECEIVER << std::endl;
    /*establish udp connection structure*/
    std::cout << "Started server" << std::endl;
    
    char buffer_input[MAX_BUFFER_SIZE];
    while (true) {
        int n = recvfrom(receive_socket,buffer_input,MAX_BUFFER_SIZE,0,(struct sockaddr*)&udp_client,&sizeOfSockaddr);
        buffer_input[n] = '\0';
        
        if (n < 0) {
            std::cerr << "Error receiving data" << std::endl;
            continue;
        }
        std::cout << "Datagram from " << inet_ntoa(udp_client.sin_addr) << 
                " port " << ntohs(udp_client.sin_port) << " with " << n << " BYTES" << std::endl;

        if(sendto(send_socket,buffer_input,n,0,(struct sockaddr*)&udp_receiver,sizeOfSockaddr) < 0){
            std::cerr << "ERROR: sendto() failed" << std::endl;
        }
    }
    return EXIT_SUCCESS;
}
