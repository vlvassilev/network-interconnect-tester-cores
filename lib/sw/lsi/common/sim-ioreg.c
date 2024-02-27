#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <assert.h>
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

#include "devmem-map.h"

static uint32_t offset;

static uint32_t get_core_offset(char* arg, unsigned int* offset)
{
    int res;
    char* ptr;
    char cmd_buf[1024];
    char offset_buf[]="0x12345678";
    FILE* f;

    sprintf(cmd_buf, "get-core-offset %s > /tmp/result", arg);

    system(cmd_buf);

    f = fopen("/tmp/result", "r");

    ptr = fgets(offset_buf, strlen(offset_buf)+1, f);

    assert(ptr==offset_buf);

    fclose(f);

    res = sscanf(offset_buf,"%x", offset);
    assert(res==1);

    return 0;
}

int ioreg_init(char* arg)
{
    int res;
    int ioreg_sock;
    struct sockaddr *ioreg_sock_name;
    int name_size;
    struct sockaddr_un ioreg_sock_name_unix;
    char *user;
    char *port;

    if(arg != NULL) {
        res = get_core_offset(arg, &offset);
        assert(res==0);
    } else {
        offset=0;
    }
    assert((offset%4096)==0);

    /* make a socket to connect to the ioreg server */
    ioreg_sock = socket(PF_LOCAL, SOCK_STREAM, 0);
    if (ioreg_sock < 0) {
        perror("Failed opening socket");
        return -1;
    } 
    ioreg_sock_name_unix.sun_family = AF_LOCAL;
    strncpy(ioreg_sock_name_unix.sun_path, 
            "/tmp/simulation", 
            sizeof(ioreg_sock_name_unix.sun_path));
    name_size = SUN_LEN(&ioreg_sock_name_unix);
    ioreg_sock_name = (struct sockaddr *)&ioreg_sock_name_unix;

    /* try to connect to the server */
    res = connect(ioreg_sock,
                  ioreg_sock_name,
                  name_size);
    if (res != 0) {
        perror("Failed connecting to server socket");
        return -1;
    }
 

    return ioreg_sock;
}

int ioreg_read(int instance_id, uint32_t address, uint32_t* value)
{
    int ret;
    char cmd[]="read 0x12345678\n";
    char rsp[]="0x12345678\n";

    sprintf(cmd, "read 0x%08X\n", address+offset);
    ret = send(instance_id, cmd, strlen(cmd), 0);
    assert(ret==strlen(cmd));
    ret = recv(instance_id, rsp, strlen(rsp), 0);
    assert(ret==strlen(rsp));
    sscanf(rsp,"0x%08X\n",value);
    return 0;
}

int ioreg_write(int instance_id, uint32_t address, uint32_t value)
{
    int ret;
    char cmd[]="write 0x12345678 0x12345678\n";
    char rsp[]="ok\n";

    sprintf(cmd, "write 0x%08X 0x%08X\n", address+offset, value);
    ret = send(instance_id, cmd, strlen(cmd), 0);
    assert(ret==strlen(cmd));
    ret = recv(instance_id, rsp, strlen(rsp), 0);
    assert(ret==strlen(rsp));
    assert(0==strcmp(rsp,"ok\n"));

    return 0;
}

int ioreg_close(int instance_id)
{
    int ret;
    ret = close(instance_id);
    return ret;
}
