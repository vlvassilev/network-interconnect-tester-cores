#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <inttypes.h>
#include <assert.h>
#include "devmem-map.h"
#include "ioreg.h"
int main(int argc, char* argv[])
{
    off_t offset= 0xa0000000;
    uint32_t reg=0;
    uint32_t *mem;
    int ret;
    int ioreg_socket;

    if(argc==2 || argc==3) {
        sscanf(argv[1], "%x", &offset);
    }
    ioreg_socket = ioreg_init(NULL);
    assert(ioreg_socket > 0);
    if(argc==2) {
        ret = ioreg_read(ioreg_socket, offset, &reg);
        assert(ret==0);
        printf("0x%08X\n",reg);
    } else if(argc==3) {
        sscanf(argv[2], "%x", &reg);
        ret = ioreg_write(ioreg_socket, offset, reg);
        assert(ret==0);
    } else {
        printf("Usage: devmem32 <reg-offset> [write-value]");
        return -1;
    }
    return 0;
}
