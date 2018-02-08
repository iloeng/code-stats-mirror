/**
 * Miscellaneous utilities
 */

import {Socket} from '../../node_modules/phoenix/priv/static/phoenix.js';

/**
 * Get live update socket for the correct backend socket path.
 *
 * Authenticates with token if available.
 */
function get_live_update_socket() {
  const meta_tag = document.getElementsByName('channel_token');

  let data = {params: {}};
  if (meta_tag.length === 1) {
    data.params.token = meta_tag[0].content;
    console.log('Authentication exists, generating socket with token', data.params.token);
  }

  return new Socket('/live_update_socket', data);
}

/**
 * Returns a promise that is resolved when page is loaded enough to run JavaScripts.
 */
function wait_for_load() {
  return new Promise(resolve => {
    // If already loaded, fire immediately
    if (/complete|interactive|loaded/.test(document.readyState)) {
      resolve();
    }
    else {
      document.addEventListener('DOMContentLoaded', resolve);
    }
  });
}

export { get_live_update_socket, wait_for_load };
