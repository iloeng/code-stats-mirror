/**
 * Code to execute on profile pages.
 */

import { get_live_update_socket } from '../common/utils';
import ProfilePageUpdater from './profile_page_updater';

let updater = null;

function debug_insert_xps(xps, machine) {
  const now = new Date();
  updater.newPulse({
    machine,
    xps,
    sent_at: now.toUTCString(),
    sent_at_local: now.toISOString()
  });
}

window.debug_insert_xps = debug_insert_xps;

function profile_page() {
  updater = new ProfilePageUpdater(get_live_update_socket());
}

export default profile_page;
