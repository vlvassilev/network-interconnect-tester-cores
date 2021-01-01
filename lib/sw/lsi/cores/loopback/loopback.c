#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <linux/mii.h>
#include <linux/sockios.h>
#include <assert.h>
#include <errno.h>

int main (int argc, char **argv)
{
    struct ifreq ifr;
    int enable;

    memset (&ifr, 0, sizeof (ifr));
    strcpy (ifr.ifr_name, argv[1]);
    enable=atoi(argv[2]);
    struct mii_ioctl_data *mii = (struct mii_ioctl_data *) (&ifr.ifr_data);
    mii->phy_id = 0x1;
    mii->reg_num = MII_BMCR;
    mii->val_in = 0;
    mii->val_out = 0;

    const int fd = socket (AF_INET, SOCK_DGRAM, 0);
    if (fd != -1) {
        if (ioctl (fd, SIOCGMIIREG, &ifr) != -1) {
            printf ("MII_BMCR     = 0x%04hX \n", mii->val_out);
            printf ("BMCR_LOOPBACK = %d \n",
	            (mii->val_out & BMCR_LOOPBACK) ? 1 : 0);
        }
    }
    if(enable) {
        mii->val_in = mii->val_out | BMCR_LOOPBACK;
    } else {
        mii->val_in = mii->val_out & ~BMCR_LOOPBACK;
    }
    if (ioctl (fd, SIOCSMIIREG, &ifr) == -1) {
        printf ("ioctl failed and returned errno %s \n", strerror (errno));
        return -1;
    }
    close (fd);
    return 0;
}
