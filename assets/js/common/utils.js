/**
 * Miscellaneous utilities
 */

import {Socket} from 'phoenix';

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
 * Returns a list of promises, one for each key in the spec, that each resolve with the data of that respective
 * spec.
 */
function request_profile(username, spec) {
  return Object.keys(spec).map(async (key) => {
    const body = `{
      profile(username: ${JSON.stringify(username)}) {
        ${key}: ${spec[key]}
      }
    }`;

    const resp =  await fetch(PROFILE_API_PATH, {
      method: 'POST',
      credentials: 'same-origin',
      mode: 'same-origin',
      body
    });

    const json = await resp.json();
    return json.data.profile;
  });
}

export { get_live_update_socket, wait_for_load, request_profile, race_promises };
