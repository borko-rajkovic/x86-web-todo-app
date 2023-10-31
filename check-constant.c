#include <sys/types.h> /* See NOTES */
#include <sys/socket.h>
#include <stdio.h>

int main(int argc, char const *argv[])
{
    printf("AF_INET = %d\n", AF_INET);
    printf("SOCK_STREAM = %d\n", SOCK_STREAM);
    return 0;
}
