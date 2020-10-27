#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <assert.h>

#include "devmem-map.h"


static int get_core_offset(char* arg, unsigned int* offset)
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

static void* mem = NULL;
int ioreg_init(char* arg)
{
    int res;
    unsigned int offset;
    res = get_core_offset(arg, &offset);
    assert(res==0);

    assert((offset%4096)==0);
    mem = devmem_map(offset, 16*1024);
    assert(mem);

    return 0;
}

int ioreg_read(int instance_id, uint32_t address, uint32_t* value)
{
    *value=*((uint32_t*)mem+address/4);
    return 0;
}

int ioreg_write(int instance_id, uint32_t address, uint32_t value)
{
    *((uint32_t*)mem+address/4)=value;
    return 0;
}

int ioreg_close(int instance_id)
{
    int res;
    res = munmap(mem, 16*1024);
    return res;
}
