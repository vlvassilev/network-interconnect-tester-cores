/*
    module lsi-power-distribution-unit
    implementation for Linux
    namespace http://lightide-instruments.com/ns/power-distribution-unit
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

#define PDU_MOD "lsi-power-distribution-unit"

static void power_distribution_unit_config(val_value_t* output_val, int enable)
{
    char cmd_buf[128];
    val_value_t* index_val;

    printf("power-distribution-unit-config:\n");
    if(output_val != NULL) {
        val_dump_value(output_val,NCX_DEF_INDENT);
    }

    index_val = val_find_child(output_val,PDU_MOD,"index");
    assert(index_val);

    sprintf(cmd_buf, "power-distribution-unit %u %u", enable?1:0, VAL_UINT32(index_val));
    log_info(cmd_buf);
    system(cmd_buf);
}


static int update_config(val_value_t* config_cur_val, val_value_t* config_new_val)
{

    status_t res;

    val_value_t *power_distribution_unit_cur_val, *output_cur_val;
    val_value_t *power_distribution_unit_new_val, *output_new_val;


    if(config_new_val == NULL) {
        power_distribution_unit_new_val = NULL;
    } else {
        power_distribution_unit_new_val = val_find_child(config_new_val,
                               PDU_MOD,
                               "power-distribution-unit");
    }

    if(config_cur_val == NULL) {
        power_distribution_unit_cur_val = NULL;
    } else {
        power_distribution_unit_cur_val = val_find_child(config_cur_val,
                                       PDU_MOD,
                                       "power-distribution-unit");
    }

    /* 2 step (delete/add) interface configuration */

    /* 1. deactivation loop - deletes all deleted or modified interface/traffic-generator -s */
    if(power_distribution_unit_cur_val!=NULL) {
        for (output_cur_val = val_get_first_child(power_distribution_unit_cur_val);
             output_cur_val != NULL;
             output_cur_val = val_get_next_child(output_cur_val)) {

            output_new_val = val123_find_match(config_new_val, output_cur_val);
            if(output_new_val==NULL || 0!=val_compare_ex(output_cur_val,output_new_val,TRUE)) {
                power_distribution_unit_config(output_cur_val,0/*enable*/); 
            }
        }
    }

    /* 2. activation loop - adds all new or modified interface/traffic-generator -s */
    if(power_distribution_unit_new_val!=NULL) {
        for (output_new_val = val_get_first_child(power_distribution_unit_new_val);
             output_new_val != NULL;
             output_new_val = val_get_next_child(output_new_val)) {

            output_cur_val = val123_find_match(config_cur_val, output_new_val);
            if(output_cur_val==NULL || 0!=val_compare_ex(output_new_val,output_cur_val,TRUE)) {
                power_distribution_unit_config(output_new_val, 1 /*enable*/);
            }
        }
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

/* The 3 mandatory callback functions: y_lsi_power_distribution_unit_init, y_lsi_power_distribution_unit_init2, y_lsi_power_distribution_unit_cleanup */

status_t
    y_lsi_power_distribution_unit_init (
        const xmlChar *modname,
        const xmlChar *revision)
{
    agt_profile_t* agt_profile;
    status_t res;
    ncx_module_t *mod;

    agt_profile = agt_get_profile();

    res = ncxmod_load_module(
        PDU_MOD,
        NULL,
        &agt_profile->agt_savedevQ,
        &mod);
    if (res != NO_ERR) {
        return res;
    }
    res=agt_commit_complete_register("lsi-power-distribution-unit" /*SIL id string*/,
                                     y_commit_complete);
    assert(res == NO_ERR);

    return res;
}

status_t y_lsi_power_distribution_unit_init2(void)
{
    status_t res=NO_ERR;
    cfg_template_t* runningcfg;

    runningcfg = cfg_get_config_id(NCX_CFGID_RUNNING);
    assert(runningcfg && runningcfg->root);

    y_commit_complete();

    return res;
}

void y_lsi_power_distribution_unit_cleanup (void)
{
}
