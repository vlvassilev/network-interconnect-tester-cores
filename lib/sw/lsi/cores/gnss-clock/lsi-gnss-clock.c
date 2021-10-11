/*
    module lsi-gnss-clock
    implementation for Linux
    namespace http://lightide-instruments.com/ns/gnss-clock
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>
#include <libxml/xmlstring.h>
#include "procdefs.h"
#include "agt.h"
#include "agt_cb.h"
#include "agt_commit_complete.h"
#include "agt_timer.h"
#include "agt_util.h"
#include "agt_not.h"
#include "agt_rpc.h"
#include "dlq.h"
#include "ncx.h"
#include "ncxmod.h"
#include "ncxtypes.h"
#include "status.h"
#include "rpc.h"
#include "val.h"
#include "val123.h"

#define GNSS_CLOCK_MOD "lsi-gnss-clock"

/* module static variables */
static ncx_module_t *lsi_gnss_clock_mod;

static void serialize_params(val_value_t* gnss_clock_val, char* cli_args_str)
{
    val_value_t* val;
    unsigned int i;

    val = val_find_child(gnss_clock_val->parent,GNSS_CLOCK_MOD,"antenna-cable-delay");
    if(val!=NULL) {
        sprintf(cli_args_str,"--antenna-cable-delay=%d",(int)VAL_INT16(val));
    }

    val = val_find_child(gnss_clock_val,GNSS_CLOCK_MOD,"rf-group-delay");
    if(val!=NULL) {
        sprintf(cli_args_str+strlen(cli_args_str)," --rf-group-delay=%d",(int)VAL_INT16(val));
    }

    val = val_find_child(gnss_clock_val,GNSS_CLOCK_MOD,"user-config-delay");
    if(val!=NULL) {
        sprintf(cli_args_str+strlen(cli_args_str)," --user-config-delay=%d",(int)VAL_INT32(val));
    }

    val = val_find_child(gnss_clock_val,GNSS_CLOCK_MOD,"frequency");
    if(val!=NULL) {
        sprintf(cli_args_str+strlen(cli_args_str)," --frequency=%u",(unsigned int)VAL_UINT32(val));
    }
}

static void gnss_clock_config(val_value_t* gnss_clock_val)
{
    char cmd_buf[4096];
    char cmd_args_buf[4096];
    char* device;

    cmd_buf[0]=0;
    cmd_args_buf[0]=0;

    printf("gnss_clock_create:\n");
    if(gnss_clock_val != NULL) {
        val_dump_value(gnss_clock_val,NCX_DEF_INDENT);
        serialize_params(gnss_clock_val, cmd_args_buf);
    } else {
        cmd_args_buf[0]=0;
    }

    device = getenv("LSI_GNSS_CLOCK_DEVICE");
    if(device==NULL) {
        device = "/dev/ttyS1";
    }

    sprintf(cmd_buf, "gnss-clock-config --device=%s %s", device, cmd_args_buf);
    log_info(cmd_buf);
    system(cmd_buf);
}

static int update_config(val_value_t* config_cur_val, val_value_t* config_new_val)
{

    status_t res;

    val_value_t *gnss_clock_cur_val;
    val_value_t *gnss_clock_new_val;

    if(config_new_val == NULL) {
        gnss_clock_new_val = NULL;
    } else {
        gnss_clock_new_val = val_find_child(config_new_val,
                               GNSS_CLOCK_MOD,
                               "gnss-clock");
    }

    if(config_cur_val == NULL) {
        gnss_clock_cur_val = NULL;
    } else {
        gnss_clock_cur_val = val_find_child(config_cur_val,
                                       GNSS_CLOCK_MOD,
                                       "gnss-clock");
    }

    if(gnss_clock_new_val==NULL && gnss_clock_new_val==NULL) {
        return NO_ERR;
    }

    if((gnss_clock_new_val==NULL && gnss_clock_cur_val!=NULL) ||
       (gnss_clock_new_val!=NULL && gnss_clock_cur_val==NULL) ||
        0!=val_compare_ex(gnss_clock_cur_val,gnss_clock_new_val,TRUE)) {

        gnss_clock_config(gnss_clock_new_val);
    }

    return NO_ERR;
}

static val_value_t* prev_root_val = NULL;
static int update_config_wrapper()
{
    cfg_template_t        *runningcfg;
    status_t res;
    runningcfg = cfg_get_config_id(NCX_CFGID_RUNNING);
    assert(runningcfg!=NULL && runningcfg->root!=NULL);
    if(prev_root_val!=NULL) {
        val_value_t* cur_root_val;
        cur_root_val = val_clone_config_data(runningcfg->root, &res);
        if(0==val_compare(cur_root_val,prev_root_val)) {
            /*no change*/
            val_free_value(cur_root_val);
            return 0;
        }
        val_free_value(cur_root_val);
    }
    update_config(prev_root_val, runningcfg->root);

    if(prev_root_val!=NULL) {
        val_free_value(prev_root_val);
    }
    prev_root_val = val_clone_config_data(runningcfg->root, &res);

    return 0;
}

static status_t y_commit_complete(void)
{
    update_config_wrapper();
    return NO_ERR;
}

/* The 3 mandatory callback functions: y_lsi_gnss_clock_init, y_lsi_gnss_clock_init2B, y_lsi_gnss_clock_cleanup */

status_t
    y_lsi_gnss_clock_init (
        const xmlChar *modname,
        const xmlChar *revision)
{
    agt_profile_t* agt_profile;
    obj_template_t* flows_obj;
    status_t res;

    agt_profile = agt_get_profile();

    res = ncxmod_load_module(
        GNSS_CLOCK_MOD,
        NULL,
        &agt_profile->agt_savedevQ,
        &lsi_gnss_clock_mod);
    if (res != NO_ERR) {
        return res;
    }
    res=agt_commit_complete_register("lsi-gnss-clock" /*SIL id string*/,
                                     y_commit_complete);
    assert(res == NO_ERR);

    return res;
}

status_t y_lsi_gnss_clock_init2(void)
{
    status_t res=NO_ERR;
    cfg_template_t* runningcfg;

    runningcfg = cfg_get_config_id(NCX_CFGID_RUNNING);
    assert(runningcfg && runningcfg->root);

    y_commit_complete();

    return res;
}

void y_lsi_gnss_clock_cleanup (void)
{
}

