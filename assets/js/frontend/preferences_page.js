import {saveAs} from 'file-saver';
import {mount, setChildren} from 'redom';

import {wait_for_load} from '../common/utils';
import LoadingIndicatorComponent from '../common/loading-indicator.component';

const EXPORT_PATH = '/my/pulses';

/**
 * Code to execute on preferences page. Adds functionality for the data export button.
 */

async function preferences_page() {
  await wait_for_load();

  const container = document.getElementById('export-data-container');
  const button = document.getElementById('export-data-button');
  const indicator_el = document.getElementById('export-data-processing');

  if (button != null) {
    button.onclick = async () => {
      container.hidden = true;
      mount(indicator_el, new LoadingIndicatorComponent());

      try {
        const resp = await fetch(EXPORT_PATH, {
          method: 'GET',
          headers: {
            'accept': 'text/csv'
          },
          credentials: 'same-origin'
        });

        const blob = await resp.blob();
        saveAs(blob, "pulses.csv", true);
      }
      catch (err) {
        alert("Error exporting data:\n\n" + err.message);
        console.error(err);
      }

      container.hidden = false;
      setChildren(indicator_el, []);
    };
  }
}

export default preferences_page;
