#include <netdb.h>
#include <sys/socket.h>
#include <stdio.h>

int main(int argc, char const *argv[])
{
    printf("AF_INET = %d\n", AF_INET);
    printf("SOCK_STREAM = %d\n", SOCK_STREAM);
    printf("INADDR_ANY = %d\n", INADDR_ANY);
    return 0;
}
