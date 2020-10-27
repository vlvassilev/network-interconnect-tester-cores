#include <stdint.h>
unsigned char hexchar2byte(char hexchar);
char byte2hexchar(unsigned char byte);
void hexstr2bin(char* hexstr, uint8_t* data);
void bin2hexstr(uint8_t* data, uint32_t len, char* hexstr);
