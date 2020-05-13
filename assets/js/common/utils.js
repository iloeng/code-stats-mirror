/**
 * Miscellaneous utilities
 */

import { Socket } from 'phoenix/assets/js/phoenix';

/**
 * Return an exponential backoff based on the given iteration.
 * @param {number} i Number of reconnect attempt (0-indexed)
 * @returns {number} Milliseconds to wait for reconnect
 */
function reconnect_backoff(i) {
  const rand = Math.random() * 90 * 1000;  // Wait for 0-90 seconds per iteration
  return rand * i;
}

/**
 * Get live update socket for the correct backend socket path.
 *
 * Authenticates with token if available.
 */
function get_live_update_socket() {
  const meta_tag = document.getElementsByName('channel_token');

  let data = {
    params: {},
    reconnectAfterMs: reconnect_backoff
  };
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

/**
 * Wait for a list of promises and complete when the first promise resolves or rejects. Resolves or rejects with
 * a tuple of the resolved/rejected value and a list of the remaining pending promises.
 *
 * If the list is empty, null is resolved.
 */
async function race_promises(promises) {
  if (promises.length === 0) {
    return null;
  }

  // Augment all promises so that they resolve or reject with a tuple that has their index.
  const mapped = promises.map((p, i) => {
    return p.then(r => [i, r]).catch(r => Promise.reject([i, r]));
  });

  const remove_promise = i => promises.splice(i, 1);

  return Promise.race(mapped)
    .then(([i, r]) => {
      remove_promise(i);
      return Promise.resolve([r, promises]);
    })
    .catch(([i, r]) => {
      remove_promise(i);
      return Promise.reject([r, promises]);
    });
}

const PROFILE_API_PATH = '/profile-graph';

/**
 * Request data from backend profile GraphQL API. `spec` should be a map of GraphQL requests for data from the
 * profile object, with keys being string names.
 *
 * Returns a promise that resolves with a map where the input keys have their respective responses, or rejects
 * on error.
 */
async function request_profile(username, spec) {
  const str_spec = Object.keys(spec).reduce((acc, key) => {
    acc += `${key}: ${spec[key]}
`;
    return acc;
  }, '');

  const body = `
    {
      profile(username: ${JSON.stringify(username)}) {
        ${str_spec}
      }
    }
  `;

  const resp = await fetch(PROFILE_API_PATH, {
    method: 'POST',
    credentials: 'same-origin',
    mode: 'same-origin',
    body
  });

  const json = await resp.json();
  return json.data.profile;
}

const HEX_MATCHER = /^#?([0-9a-f]{6})$/i;

/**
 * Convert given hex string (with optional preceding #) to an RGB object.
 * @param {String} hex_str
 * @returns {{r: Number, g: Number, b: Number}}
 */
function hex_to_color(hex_str) {
  const parts = hex_str.match(HEX_MATCHER)[1];
  return {
    r: parseInt(parts.substr(0, 2), 16),
    g: parseInt(parts.substr(2, 2), 16),
    b: parseInt(parts.substr(4, 2), 16)
  };
}

/**
 * Convert given RGB object to a CSS RGB string.
 * @param {{r: Number, g: Number, b: Number}} param0 
 * @returns {String}
 */
function color_to_rgb_str({ r, g, b }) {
  return `rgb(${r}, ${g}, ${b})`;
}

export {
  get_live_update_socket,
  wait_for_load,
  request_profile,
  race_promises,
  hex_to_color,
  color_to_rgb_str,
};
