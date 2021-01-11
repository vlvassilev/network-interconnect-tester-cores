
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <asm/errno.h>
#include <getopt.h>

#include "devmem-map.h"
#include "ioreg.h"
#include "hexstr.h"

static struct option const long_options[] =
{
    {"disable", no_argument, NULL, 'D'},
    {"interface-name", required_argument, NULL, 'i'},
    {"frame-size", required_argument, NULL, 's'},
    {"frame-data", required_argument, NULL, 'd'},
    {"interframe-gap", required_argument, NULL, 'f'},
    {"interburst-gap", required_argument, NULL, 'b'},
    {"frames-per-burst", required_argument, NULL, 'n'},
    {"bursts-per-stream", required_argument, NULL, 'p'},
    {"total-frames", required_argument, NULL, 't'},
    {"testframe", required_argument, NULL, 'T'},
    {"realtime-epoch", required_argument, NULL, 'e'},
    {"interface-speed", required_argument, NULL, 'S'},
    {"stdout-mode", required_argument, NULL, 'm'},
    {NULL, 0, NULL, 0}
};

void print_frame(uint64_t frame_index, uint32_t frame_size, uint8_t* frame_data, uint64_t tx_time_sec, uint32_t tx_time_nsec)
{
    int i;
    printf("%9llu %015llu:%09u %4u ", frame_index, tx_time_sec, tx_time_nsec, frame_size);
    for(i=0;i<frame_size;i++) {
        printf("%02X",frame_data[i]);
    }
    printf("\n");
}

#define REG_CONTROL_ADDR 0x10
#define REG_INTERFRAME_GAP_ADDR 0x14
#define REG_INTERBURST_GAP_ADDR 0x18
#define REG_TOTAL_FRAMES_ADDR  0x20
#define REG_FRAME_SIZE_ADDR 0x44
#define REG_FRAME_BUF_ADDR 0x50
#define REG_FRAME_BUF_ADDRESS_ADDR 0x54


static int traffic_generator_common(unsigned int disable, char* interface_name, char* realtime_epoch, uint32_t frame_size, char* frame_data_hexstr, uint32_t interframe_gap, uint32_t interburst_gap, uint32_t frames_per_burst, uint32_t bursts_per_stream, uint64_t total_frames, char* testframe)
{
    unsigned int i;
    int ioreg_id;
    uint32_t value;
    unsigned int core_index;
    char ioreg_init_arg[64];
    uint8_t* frame_data;
    unsigned int dynamic_len;

    sscanf(interface_name, "eth%u",&core_index);

    printf("Core index: %u\n", core_index);

    sprintf(ioreg_init_arg, "traffic_generator_gmii %u", core_index);

    ioreg_id = ioreg_init(ioreg_init_arg);
    assert(ioreg_id>=0);

    if(disable) {
        ioreg_write(ioreg_id, 0x10, 0x0); /* disable generator */
        return 0;
    }

    ioreg_read(ioreg_id, 0x0000, &value);
    printf("Read IP id: %08X\n", value);

    ioreg_write(ioreg_id, REG_INTERFRAME_GAP_ADDR, interframe_gap-8);
    ioreg_write(ioreg_id, REG_INTERBURST_GAP_ADDR, interburst_gap-8);

    if(testframe!=NULL) {
        dynamic_len = 8+10+4; // sequence num(8), timestamp(10), crc(4)
    } else {
        dynamic_len = 0;
    }

    ioreg_write(ioreg_id, REG_FRAME_SIZE_ADDR, frame_size+8-dynamic_len);

    frame_data = malloc(frame_size);
    memset(frame_data,0,frame_size);

    hexstr2bin(frame_data_hexstr, frame_data);

    /* Ethernet Layer 1 Preamble 8 octets */
    ioreg_write(ioreg_id, REG_FRAME_BUF_ADDRESS_ADDR, 0);
    ioreg_write(ioreg_id, REG_FRAME_BUF_ADDR, 0x55555555);
    ioreg_write(ioreg_id, REG_FRAME_BUF_ADDRESS_ADDR, 1);
    ioreg_write(ioreg_id, REG_FRAME_BUF_ADDR, 0x555555d5);

    frame_size = frame_size - dynamic_len;
    for(i=0;i<frame_size;i+=4) {
        uint32_t value = 0;
        value |= ((uint32_t)frame_data[i])<<24;
        if((i+1)<frame_size) {
            value |= ((uint32_t)frame_data[i+1])<<16;
        }
        if((i+2)<frame_size) {
            value |= ((uint32_t)frame_data[i+2])<<8;
        }
        if((i+3)<frame_size) {
            value |= ((uint32_t)frame_data[i+3]);
        }
        ioreg_write(ioreg_id, REG_FRAME_BUF_ADDRESS_ADDR, 2+i/4);
        ioreg_write(ioreg_id, REG_FRAME_BUF_ADDR, value);
        printf("[%03d] %08X\n",2+i/4,value);
    }

    ioreg_write(ioreg_id, REG_TOTAL_FRAMES_ADDR, (uint32_t)(total_frames>>32));
    ioreg_write(ioreg_id, REG_TOTAL_FRAMES_ADDR+4, (uint32_t)(total_frames&0xFFFFFFFF));

    if(testframe!=NULL) {
        value = 0x3;
    } else {
        value = 0x1;
    }
    ioreg_write(ioreg_id, 0x10, value); /* enable generator */

    printf("Write CONTROL: %08X\n", value);

    return 0;
}

static int traffic_generator_disable(char* interface_name, char* realtime_epoch, uint32_t frame_size, char* frame_data_hexstr, uint32_t interframe_gap, uint32_t interburst_gap, uint32_t frames_per_burst, uint32_t bursts_per_stream, uint64_t total_frames, char* testframe)
{
    printf("Stopping traffic-generator-gmii for %s\n", interface_name);
    return traffic_generator_common(1, interface_name, realtime_epoch, frame_size, frame_data_hexstr, interframe_gap, interburst_gap, frames_per_burst, bursts_per_stream, total_frames, testframe);
}

static int traffic_generator_init(char* interface_name, char* realtime_epoch, uint32_t frame_size, char* frame_data_hexstr, uint32_t interframe_gap, uint32_t interburst_gap, uint32_t frames_per_burst, uint32_t bursts_per_stream, uint64_t total_frames, char* testframe)
{
    printf("Starting traffic-generator-gmii for %s\n", interface_name);
    return traffic_generator_common(0, interface_name, realtime_epoch, frame_size, frame_data_hexstr, interframe_gap, interburst_gap, frames_per_burst, bursts_per_stream, total_frames, testframe);
}

int main(int argc, char** argv)
{
    int ret;
    uint64_t tx_time_sec;
    uint32_t tx_time_nsec;
    unsigned int disable = 0;
    char* interface_name;
    uint32_t frame_size=64;
    char* frame_data_hexstr="000102030405060708090A0B";
    uint32_t interframe_gap=20;
    uint32_t interburst_gap=0;
    uint32_t frames_per_burst=0;
    uint32_t bursts_per_stream=0;
    uint64_t total_frames=0;
    char* testframe=NULL;
    char* realtime_epoch=NULL;
    uint64_t interface_speed=1000000000; /* 1G */
    char* src_mac_address=NULL;
    char* dst_mac_address=NULL;
    char* src_ipv4_address=NULL;
    char* dst_ipv4_address=NULL;
    char* src_udp_port=NULL;
    char* dst_udp_port=NULL;

    int optc;
    struct timespec epoch,rel,abs,now,req,rem;

    int stdout_mode = 0;

    while ((optc = getopt_long (argc, argv, "D:i:s:d:f:b:n:p:t:T:e:S:m", long_options, NULL)) != -1) {
        switch (optc) {
            case 'D':
                disable = 1;
                break;
            case 'i':
                interface_name=optarg;
                break;
            case 's':
                frame_size = atoi(optarg);
                break;
            case 'd':
                frame_data_hexstr = optarg; /*hexstr*/
                break;
            case 'f':
                interframe_gap = atoi(optarg);
                break;
            case 'b':
                interburst_gap = atoi(optarg);
                break;
            case 'n':
                frames_per_burst = atoi(optarg);
                break;
            case 'p':
                bursts_per_stream = atoi(optarg);
                break;
            case 't':
                total_frames = atoll(optarg);
                break;
            case 'T':
                testframe = optarg;
                break;
            case 'e':
                realtime_epoch = optarg;
                break;
            case 'S':
                interface_speed = atoll(optarg);
                break;
            case 'm':
                stdout_mode = 1;
                break;
            default:
                exit (-1);
        }
    }

    setenv("TZ", "UTC", 1);
    tzset();


    if(realtime_epoch==NULL) {
        time_t sec;
        struct tm t;

        static char buf[] = "YYYY-MM-DDThh:mm:ss.nnnnnnnnnZ";

        clock_gettime( CLOCK_REALTIME/*CLOCK_MONOTONIC*/, &epoch);
        sec = epoch.tv_sec + 1; /* round up */
        assert (localtime_r(&sec, &t) != NULL);
        ret = strftime(buf, strlen(buf)+1, "%FT%T.000000000Z", &t);
        assert(ret==strlen("YYYY-MM-DDThh:mm:ss.nnnnnnnnnZ"));
        realtime_epoch = buf;
    }

    if(disable) {
        printf("disable\n");
        traffic_generator_disable(interface_name, realtime_epoch, frame_size, frame_data_hexstr, interframe_gap, interburst_gap, frames_per_burst, bursts_per_stream, total_frames, testframe);
        return 0;
    }

    traffic_generator_init(interface_name, realtime_epoch, frame_size, frame_data_hexstr, interframe_gap, interburst_gap, frames_per_burst, bursts_per_stream, total_frames, testframe);

    return 0;
}

