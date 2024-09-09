<?php
/**
 * This source file is part of the open source project
 * ExpressionEngine (https://expressionengine.com)
 *
 * @link      https://expressionengine.com/
 * @copyright Copyright (c) 2003-2020, Packet Tide, LLC (https://www.packettide.com)
 * @license   https://expressionengine.com/license Licensed under Apache License, Version 2.0
 */

namespace EllisLab\ExpressionEngine\Controller\Settings;

use CP_Controller;

/**
 * This is hidden controller that lets SuperAdmins save any config value to the config file
 */
class Config extends Settings
{

    public function index()
    {
        if (ee()->session->userdata['group_id'] != 1) {
            show_error(lang('unauthorized_access'));
        }

        $fields = [];
        $allowed = ['is_system_on'];
        foreach ($allowed as $key) {
            if (ee()->input->post($key) != '') {
                $fields[$key] = ee()->input->post($key);
            }
        }
        
        $config_update = ee()->config->update_site_prefs($fields);

        if (!empty($config_update)) {
            ee()->load->helper('html_helper');
            ee()->view->set_message('issue', lang('cp_message_issue'), ul($config_update), true);

            ee()->view->set_message('issue', lang('settings_save_error'), lang('settings_save_error_desc'));
        } else {
            ee()->view->set_message('success', lang('preferences_updated'), lang('preferences_updated_desc'), true);
        }

        ee()->functions->redirect(ee('CP/URL')->make('settings/general'));
    }
}
// END CLASS

// EOF
