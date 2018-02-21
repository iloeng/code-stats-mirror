import {el, list} from 'redom';
import CombinedLevelProgressComponent from '../../graphs/combined-level-progress.component';
import ListableLevelCounterComponent from '../../graphs/listable-level-counter.component';

// How many languages to show in top list at maximum
const MAX_TOP_LANGS = 10;

class TopLanguagesComponent {
  constructor(data_source) {
    this.list = list('div', CombinedLevelProgressComponent, null, ['h4']);

    this.el = el('section.top-languages', [this.list]);

    this._langs = [];
    this._dataSource = data_source;
  }

  setInitData() {
    this._langs = this._dataSource.getTopLangs();
    this._updateElems();
  }

  update() {
    this._langs = this._dataSource.getTopLangs();
    this._updateElems();
  }

  _updateElems() {
    this.list.update(this._langs);
  }
}

export default TopLanguagesComponent;
