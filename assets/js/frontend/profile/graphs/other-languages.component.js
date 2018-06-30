import { el, list } from 'redom';
import ListableLevelCounterComponent from '../../graphs/listable-level-counter.component';

class OtherLanguagesComponent {
  constructor(data_source) {
    this.list = list('ul', ListableLevelCounterComponent, null, ['li', '', 0, 0]);

    this.title = el('h4', 'Other languages');

    this.el = el('section.other-languages', [
      this.title,
      this.list
    ]);

    this._langs = [];
    this._dataSource = data_source;
  }

  setInitData() {
    this._refresh();
  }

  update() {
    this._refresh();
  }

  _refresh() {
    this._langs = this._dataSource.getOtherLangs();
    this.list.update(this._langs);
    this.title.style.display = (this._langs.length > 0) ? 'block' : 'none';
  }
}

export default OtherLanguagesComponent;
