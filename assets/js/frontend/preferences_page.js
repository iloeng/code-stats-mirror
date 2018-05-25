import { saveAs } from 'file-saver';
import { mount, setChildren } from 'redom';

import { wait_for_load } from '../common/utils';
import LoadingIndicatorComponent from '../common/loading-indicator.component';
import TabComponent from '../common/tab.component';

const XP_EXPORT_PATH = '/my/pulses';
const PRIVATE_EXPORT_PATH = '/my/private';

/**
 * Code to execute on preferences page. Adds functionality for the data export button.
 */

async function preferences_page() {
  await wait_for_load();

  const container = document.getElementById('export-data-container');
  const button = document.getElementById('export-data-button');
  const indicator_el = document.getElementById('export-data-processing');
  const include_private_el = document.getElementById('include-private-data');

  if (button != null) {
    button.onclick = async () => {
      container.hidden = true;
      mount(indicator_el, new LoadingIndicatorComponent());

      const include_private = include_private_el.checked;

      const promises = [
        fetch(XP_EXPORT_PATH, {
          method: 'GET',
          headers: {
            'accept': 'text/csv'
          },
          credentials: 'same-origin'
        })
      ];

      if (include_private) {
        promises.push(
          fetch(PRIVATE_EXPORT_PATH, {
            method: 'GET',
            headers: {
              'accept': 'text/csv'
            },
            credentials: 'same-origin'
          })
        );
      }

      try {
        const resp = await Promise.all(promises);

        const blob = await resp[0].blob();
        saveAs(blob, "pulses.csv", true);

        if (resp.length === 2) {
          // Wait for a moment before continuing, to fix downloading multiple files on Chrome
          // See https://github.com/eligrey/FileSaver.js/issues/435

          setTimeout(async () => {
            const blob = await resp[1].blob();
            saveAs(blob, "private.csv", true);
          }, 500);
        }
      }
      catch (err) {
        alert("Error exporting data:\n\n" + err.message);
        console.error(err);
      }

      container.hidden = false;
      setChildren(indicator_el, []);
    };
  }

  const tab_container = document.getElementById('tab-container');
  mount(tab_container, new TabComponent([
    ['user-details', 'User details'],
    ['change-password', 'Change password'],
    ['export-data', 'Export data'],
    ['delete-account', 'Delete account'],
  ], 'preferences-container'));
}

export default preferences_page;
