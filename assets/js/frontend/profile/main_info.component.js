import { el, mount, setChildren } from 'redom';
import LoadingIndicatorComponent from '../../common/loading-indicator.component';
import StartupInstructionsComponent from './startup-instructions.component';
import { DateTime } from 'luxon';
import { RECENT_HOURS } from '../config';

import LanguagesDataSource from './graphs/languages.data-source';
import TopLanguagesComponent from './graphs/top-languages.component';
import OtherLanguagesComponent from './graphs/other-languages.component';
import TopMachinesComponent from './graphs/top-machines.component';
import YearXpsComponent from './graphs/year-xps.component';
import WeekLanguagesComponent from './graphs/week-languages.component';

/**
 * MainInfoComponent handles showing either the loading indicator, startup instructions, or list of graphs, and
 * propagates all data updates to those graphs.
 */
class MainInfoComponent {
  constructor(total_xp) {
    this.el = el('div.main-info-graphs', []);

    this._loading = true;

    // Does user have no data? If so, show startup instructions
    this._noData = total_xp === 0;

    // List of child graphs that should be sent data updates
    this._graphs = [];

    // Data source for top languages components
    this._langDataSource = new LanguagesDataSource();
  }

  getDataRequest() {
    const now = DateTime.utc();
    const since_recent = now.minus({ hours: RECENT_HOURS });
    const since_14d = now.minus({ weeks: 2 });

    return {
      total_machines: 'machines {name xp}',
      recent_machines: `machines(since: ${JSON.stringify(since_recent.toISO())}) {name xp}`,
      day_language_xps: `dayLanguageXps(since: ${JSON.stringify(since_14d.toISODate())}) {date language xp}`,
      day_of_year_xps: `dayOfYearXps`,
    };
  }

  setInitData(data) {
    console.log('setInitData', data);

    this._langDataSource.setInitData(data);

    for (const graph of this._graphs) {
      graph.setInitData(data);
    }
  }

  update(data) {
    // Incoming pulse, if startup instructions are shown, replace them with stats list at this point
    if (this._noData) {
      this._noData = false;
      this._showCorrectComponents();
    }

    console.log('update', data);

    this._langDataSource.update(data);

    for (const graph of this._graphs) {
      graph.update(data);
    }
  }

  setLoadingStatus(status) {
    this._loading = status;

    if (this._loading) {
      setChildren(this.el, [new LoadingIndicatorComponent()]);
    }
    else {
      this._showCorrectComponents();
    }
  }

  _buildStatsElems() {
    const now = DateTime.utc();
    const since_14d = now.minus({ weeks: 2 });

    this._graphs = [
      new TopLanguagesComponent(this._langDataSource),
      new OtherLanguagesComponent(this._langDataSource),
      new TopMachinesComponent(),
      new YearXpsComponent(),
      new WeekLanguagesComponent(since_14d, now),
    ];
  }

  _showCorrectComponents() {
    if (this._noData) {
      this._graphs = [];
      setChildren(this.el, [new StartupInstructionsComponent()]);
    }
    else {
      this._buildStatsElems();
      setChildren(this.el, this._graphs);
    }
  }
}

export default MainInfoComponent;
