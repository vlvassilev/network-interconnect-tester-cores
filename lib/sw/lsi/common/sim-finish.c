#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <unistd.h>
#include <inttypes.h>
#include <assert.h>
#include "devmem-map.h"
#include "ioreg.h"

#include <stdint.h>
#include <string.h>

int main(int argc, char* argv[])
{
    int ret;
    int ioreg_socket;
    char rsp[]="ok\n";

    assert(argc==1);

    ioreg_socket = ioreg_init(NULL);
    assert(ioreg_socket > 0);

    ret = send(ioreg_socket, "finish\n", strlen("finish\n"), 0);
    assert(ret==strlen("finish\n"));

    ret = recv(ioreg_socket, rsp, strlen(rsp), 0);
    assert(ret==strlen(rsp));
    assert(0==strcmp(rsp,"ok\n"));

    return 0;
}
