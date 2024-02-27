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
    uint32_t ticks= 0;
    char units[32]="ns";
    char buf[256];
    int ret;
    int ioreg_socket;
    char rsp[]="ok\n";

    if(argc==2 || argc==3) {
        sscanf(argv[1], "%u", &ticks);
    } else {
        assert(0);
    }
    if(argc==3) {
        sscanf(argv[2], "%s", units);
    }

    ioreg_socket = ioreg_init(NULL);
    assert(ioreg_socket > 0);

    sprintf(buf, "run %u %s\n", ticks, units);
    ret = send(ioreg_socket, buf, strlen(buf), 0);
    assert(ret==strlen(buf));

    ret = recv(ioreg_socket, rsp, strlen(rsp), 0);
    assert(ret==strlen(rsp));
    assert(0==strcmp(rsp,"ok\n"));

    return 0;
}
