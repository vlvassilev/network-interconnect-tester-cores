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

#define REG_ID_ADDR      0x00
#define REG_VERSION_ADDR 0x04
#define REG_FLIP_ADDR	 0x0C
#define REG_CONTROL_ADDR 0x10
#define REG_PKTS_ADDR	 0x20
#define REG_OCTETS_ADDR	 0x28
#define REG_OCTETS_IDLE_ADDR	0x30
#define REG_TIMESTAMP_SEC_ADDR	0x38
#define REG_TIMESTAMP_NSEC_ADDR	0x40
#define REG_FRAME_SIZE_ADDR	0x44
#define REG_FRAME_BUF_ADDR	0x50
#define REG_BAD_CRC_PKTS_ADDR   0x58
#define REG_BAD_CRC_OCTETS_ADDR 0x60
#define REG_BAD_PREAMBLE_PKTS_ADDR   0x68
#define REG_BAD_PREAMBLE_OCTETS_ADDR 0x70
#define REG_OCTETS_TOTAL_ADDR 0x78

static struct option const long_options[] =
{
    {"interface-name", required_argument, NULL, 'i'},
    {"verbose", no_argument, NULL, 'v'},
    {NULL, 0, NULL, 0}
};

int main(int argc, char** argv)
{
    int ret;
    unsigned int i;
    char* interface_name;
    int verbose=0;
    int optc;
    unsigned int core_index;
    char ioreg_init_arg[64];
    int ioreg_id;
    uint32_t lsb;
    uint32_t msb;
    uint64_t pkts;
    uint64_t octets;
    uint64_t octets_idle;
    uint64_t bad_crc_octets;
    uint64_t bad_crc_pkts;
    uint64_t bad_preamble_octets;
    uint64_t bad_preamble_pkts;
    uint64_t octets_total;
    uint32_t frame_size;
    uint32_t frame_data;

    while ((optc = getopt_long (argc, argv, "i:v", long_options, NULL)) != -1) {
        switch (optc) {
            case 'i':
                interface_name=optarg;
                break;
            case 'v':
                verbose=1;
                break;
            default:
                exit (-1);
        }
    }

    sscanf(interface_name, "eth%u",&core_index);

    sprintf(ioreg_init_arg, "traffic_analyzer_gmii %u", core_index);

    ioreg_id = ioreg_init(ioreg_init_arg);
    assert(ioreg_id>=0);

    ioreg_write(ioreg_id, REG_CONTROL_ADDR, 0x1); /* start */

    while(1) {
        ret = getc(stdin);
        if(ret==EOF) {
            exit(0);
        }

        ioreg_write(ioreg_id, REG_CONTROL_ADDR, 0x2|0x1); /* freeze status registers without stopping */
        ioreg_read(ioreg_id, REG_PKTS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_PKTS_ADDR+4, &lsb);
        pkts = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_OCTETS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_OCTETS_ADDR+4, &lsb);
        octets = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_OCTETS_IDLE_ADDR, &msb);
        ioreg_read(ioreg_id, REG_OCTETS_IDLE_ADDR+4, &lsb);
        octets_idle = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_BAD_CRC_OCTETS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_BAD_CRC_OCTETS_ADDR+4, &lsb);
        bad_crc_octets = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_BAD_CRC_PKTS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_BAD_CRC_PKTS_ADDR+4, &lsb);
        bad_crc_pkts = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_BAD_PREAMBLE_OCTETS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_BAD_PREAMBLE_OCTETS_ADDR+4, &lsb);
        bad_preamble_octets = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_BAD_PREAMBLE_PKTS_ADDR, &msb);
        ioreg_read(ioreg_id, REG_BAD_PREAMBLE_PKTS_ADDR+4, &lsb);
        bad_preamble_pkts = (uint64_t)msb<<32 | lsb;
        ioreg_read(ioreg_id, REG_OCTETS_TOTAL_ADDR, &msb);
        ioreg_read(ioreg_id, REG_OCTETS_TOTAL_ADDR+4, &lsb);
        octets_total = (uint64_t)msb<<32 | lsb;

        ioreg_read(ioreg_id, REG_FRAME_SIZE_ADDR, &frame_size);

        ioreg_write(ioreg_id, REG_CONTROL_ADDR, 0x1); /* unfreeze status registers */

        printf("<state xmlns=\"urn:ietf:params:xml:ns:yang:ietf-traffic-analyzer\"><pkts>%llu</pkts><octets>%llu</octets><octets-idle>%llu</octets-idle>"
        "<bad-crc-octets>%llu</bad-crc-octets><bad-crc-pkts>%llu</bad-crc-pkts>"
        "<bad-preamble-octets>%llu</bad-preamble-octets><bad-preamble-pkts>%llu</bad-preamble-pkts>"
        "<octets-total>%llu</octets-total>"
        "<testframe-stats><testframe-pkts>%llu</testframe-pkts></testframe-stats>",
                pkts,
                octets,
                octets_idle,
                bad_crc_octets,
                bad_crc_pkts,
                bad_preamble_octets,
                bad_preamble_pkts,
                octets_total,
                pkts /*TODO*/);
        printf("<capture><sequence-number>%llu</sequence-number><data>",
                pkts);

        for(i=0;i<(frame_size/4);i++) {
            ioreg_read(ioreg_id, REG_FRAME_BUF_ADDR, &frame_data);
            usleep(1000);
            printf("%08X",frame_data);
        }
        for(i=0;i<(frame_size%4);i++) {
            if(i==0) {
                ioreg_read(ioreg_id, REG_FRAME_BUF_ADDR, &frame_data);
                printf("%02X",(frame_data>>24) & 0xFF);
            } else if(i==1) {
                printf("%02X",(frame_data>>16) & 0xFF);
            } else if(i==2) {
                printf("%02X",(frame_data>>8) & 0xFF);
            }
        }
        printf("</data></capture>");
        printf("</state>\n");

        fflush(stdout);
    }
}
