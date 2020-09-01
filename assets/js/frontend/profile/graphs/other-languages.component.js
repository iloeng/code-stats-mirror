import { el, list, svg } from 'redom';
import ListableLevelCounterComponent from '../../graphs/listable-level-counter.component';
import { graphButton } from '../../../common/graph-buttons';

const MAX_LANGS_DEFAULT = 10;

// ARIA needs a unique ID, use this to generate one
let olc_id = 0;

class OtherLanguagesComponent {
  constructor(data_source) {
    ++olc_id;

    this.downBtn = graphButton(
      'chevron-bottom',
      'M1.5 0l-1.5 1.5 4 4 4-4-1.5-1.5-2.5 2.5-2.5-2.5z',
      { transform: 'translate(0 1)' }
    );

    this.upBtn = graphButton(
      'chevron-top',
      'M4 0l-4 4 1.5 1.5 2.5-2.5 2.5 2.5 1.5-1.5-4-4z',
      { transform: 'translate(0 1)' }
    );

    this.list = list(
      el('ul', { id: `other-languages-list-${olc_id}` }),
      ListableLevelCounterComponent,
      null,
      ['li', '', 0, 0]
    );

    this.title = el('h4', 'Other languages');

    this.showAllEl = el(
      'button',
      {
        type: 'button',
        class: 'show-all-link',
        'aria-controls': `other-languages-list-${olc_id}`
      }
    );
    this.showAllEl.addEventListener('click', () => this._showAll());

    this.el = el('section.other-languages', [
      this.title,
      this.list,
      this.showAllEl
    ]);

    this._langs = [];
    this._dataSource = data_source;
    this._showingAll = false;
  }

  setInitData() {
    this._refresh();
  }

  update() {
    this._refresh();
  }

  _showAll() {
    this._showingAll = !this._showingAll;
    this._refresh();
  }

  _refresh() {
    const allLangs = this._dataSource.getOtherLangs();
    this._langs = allLangs;

    if (!this._showingAll) {
      this._langs = this._langs.slice(0, MAX_LANGS_DEFAULT);
      this.upBtn.remove();
      this.showAllEl.appendChild(this.downBtn);
      this.showAllEl.title = 'Show more';
    } else {
      this.downBtn.remove();
      this.showAllEl.appendChild(this.upBtn);
      this.showAllEl.title = 'Show less';
    }

    this.list.update(this._langs);
    this.el.style.display = (this._langs.length > 0) ? 'block' : 'none';
    this.showAllEl.style.display = (allLangs.length > MAX_LANGS_DEFAULT) ? 'block' : 'none';
  }
}

export default OtherLanguagesComponent;
