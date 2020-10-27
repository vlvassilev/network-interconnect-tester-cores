#include <stdint.h>
#include <string.h>
#include <assert.h>

unsigned char hexchar2byte(char hexchar)
{
    char byte;
    if(hexchar>='0' && hexchar<='9') {
        byte = hexchar - '0';
    } else if (hexchar>='A' && hexchar<='F') {
        byte = hexchar - 'A' + 10;
    } else if (hexchar>='a' && hexchar<='f') {
        byte = hexchar - 'a' + 10;
    } else {
        assert(0);
    }
    return byte;
}

char byte2hexchar(unsigned char byte)
{
    char hexchar;
    if(byte>=0 && byte<=9) {
        hexchar = byte + '0';
    } else if (byte>=0xA && byte<=0xF) {
        hexchar = byte + 'A'-0xA;
    } else {
        assert(0);
    }
    return hexchar;
}

void hexstr2bin(char* hexstr, uint8_t* data)
{
    unsigned int i;
    unsigned int len;

    len = strlen(hexstr)/2;

    for(i=0;i<len;i++) {
        data[i] = (hexchar2byte(hexstr[i*2])<<4) | (hexchar2byte(hexstr[i*2+1]));
    }
}

void bin2hexstr(uint8_t* data, uint32_t len, char* hexstr)
{
    unsigned int i;


    for(i=0;i<len;i++) {
        hexstr[2*i] = byte2hexchar(data[i]>>4);
        hexstr[2*i+1] = byte2hexchar(data[i]&0xF);
    }
    hexstr[2*len]=0;
}

