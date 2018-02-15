import {el, mount, setChildren} from 'redom';
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
    return {};
  }

  setInitData(data) {
    console.log(data);
  }

  update(data) {

  }
}

export default MainInfoComponent;
