import 'core-js/es6/promise';
import 'whatwg-fetch';
import {saveAs} from 'file-saver';

import {wait_for_load} from '../../common/js/utils';

const EXPORT_PATH = '/my/pulses';

/**
 * Code to execute on preferences page. Adds functionality for the data export button.
 */

function preferences_page() {
  wait_for_load().then(() => {
    const button = document.getElementById('export-data-button');

    if (button != null) {
      button.onclick = () => {
        button.textContent = 'Processing…';
        button.disabled = true;

        fetch(EXPORT_PATH, {
          method: 'GET',
          headers: {
            'accept': 'text/csv'
          },
          credentials: 'same-origin'
        })
        .then(resp => resp.blob())
        .then(blob => {
          saveAs(blob, "pulses.csv", true);
        })
        .catch(err => alert("Error exporting data:\n\n" + err.message))
        .finally(() => {
          button.textContent = 'Download data';
          button.disabled = false;
        });
      };
    }
  });
}

export default preferences_page;
