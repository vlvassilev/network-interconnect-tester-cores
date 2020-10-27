#include <stdint.h>
int ioreg_init(char* arg);
int ioreg_read(int instance_id, uint32_t address, uint32_t* value);
int ioreg_write(int instance_id, uint32_t address, uint32_t value);
int ioreg_close(int instance_id);
