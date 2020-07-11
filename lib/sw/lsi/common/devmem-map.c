#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <assert.h>

void* devmem_map(off_t offset, size_t len)
{

    int fd;
    unsigned int *mem;
    fd = open("/dev/mem", (O_RDWR | O_SYNC));
    mem = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);

    assert(mem!=NULL);
    return mem;
}

