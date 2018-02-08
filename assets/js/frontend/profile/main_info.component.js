import {el, mount, setChildren} from 'redom';
import {DateTime} from 'luxon';
import LoadingIndicatorComponent from '../../common/loading-indicator.component';
import StartupInstructionsComponent from './startup-instructions.component';

import TopLanguagesComponent from './graphs/top-languages.component';

class MainInfoComponent {
  constructor() {

    this.topLanguages = new TopLanguagesComponent();

    this.el = el('div', [
      new StartupInstructionsComponent()
    ]);
  }

  getDataRequest() {
    const now = DateTime.utc();

    const since_recent = now.minus({hours: 12});

    return {
      total_langs: 'languages {name xp}',
      recent_langs: `languages(since: ${since_recent}) {name xp}`
    };
  }

  setInitData(data) {
    console.log(data);
  }

  update(data) {

  }
}

export default MainInfoComponent;
