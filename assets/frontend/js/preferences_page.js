import 'core-js/es6/promise';
import 'whatwg-fetch';
import {saveAs} from 'file-saver';
import {mount, setChildren} from 'redom';

import {wait_for_load} from '../../common/js/utils';
import LoadingIndicatorComponent from '../../common/js/loading-indicator.component';

const EXPORT_PATH = '/my/pulses';

/**
 * Code to execute on preferences page. Adds functionality for the data export button.
 */

function preferences_page() {
  wait_for_load().then(() => {
    const container = document.getElementById('export-data-container');
    const button = document.getElementById('export-data-button');
    const indicator_el = document.getElementById('export-data-processing');

    if (button != null) {
      button.onclick = () => {
        container.hidden = true;
        mount(indicator_el, new LoadingIndicatorComponent());

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
          container.hidden = false;
          setChildren(indicator_el, []);
        });
      };
    }
  });
}

export default preferences_page;
