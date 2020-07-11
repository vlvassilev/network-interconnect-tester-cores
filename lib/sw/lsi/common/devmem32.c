#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <inttypes.h>
#include <assert.h>
#include <devmem-map.h>

int main(int argc, char* argv[])
{
    off_t offset= 0xa0000000;
    uint32_t reg=0;
    uint32_t *mem;

    if(argc==2 || argc==3) {
        sscanf(argv[1], "%x", &offset);
    }
    mem = devmem_map(offset-(offset%4096), 4096);
    if(argc==2) {
        reg=*(mem+(offset%4096)/4);
        printf("0x%08x\n",reg);
    } else if(argc==3) {
        sscanf(argv[2], "%x", &reg);
        *(mem+(offset%4096)/4)=reg;
    } else {
        printf("Usage: devmem32 <reg-offset> [write-value]");
        return -1;
    }
    return 0;
}
