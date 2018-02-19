import {el, list} from 'redom';
import CombinedLevelProgressComponent from '../../graphs/combined-level-progress.component';
import LevelCounterComponent from '../../graphs/level_counter.component';

// How many languages to show in top list at maximum
const MAX_TOP_LANGS = 10;

class TopLanguagesComponent {
  constructor() {
    this.topLangList = list('div', CombinedLevelProgressComponent, null, ['h4']);
    this.otherLangList = list('div');

    this.el = el('section.top-languages', [
      el('div.top-lang-list', [this.topLangList]),
      el('div.other-lang-list', [this.otherLangList])
    ]);

    // List of language objects {name, xp, recent_xp}
    this._languages = [];
  }

  setInitData({total_langs, recent_langs}) {
    if (total_langs != null) {
      for (const {name, xp} of total_langs) {
        this._updateLang(name, l => {
          l.xp = xp;
          return l;
        });
      }
    }

    if (recent_langs != null) {
      for (const {name, xp} of recent_langs) {
        this._updateLang(name, l => {
          l.recent_xp = xp;
          return l;
        });
      }
    }

    this._sortLangs();
    this._updateElems();
  }

  update({xps}) {
    for (const {language, amount} of xps) {
      this._updateLang(language, l => {
        l.xp += amount;
        l.recent_xp += amount;
        return l;
      });
    }

    this._sortLangs();
    this._updateElems();
  }

  // Update a single language with the given operation
  _updateLang(name, update_fun) {
    const idx = this._languages.findIndex(l => l.name === name);

    if (idx === -1) {
      const lang = update_fun({name, xp: 0, recent_xp: 0});
      this._languages.push(lang);
    }
    else {
      const lang = update_fun(this._languages[idx]);
      this._languages.splice(idx, 1, lang);
    }
  }

  _updateElems() {
    const top_langs = this._languages.slice(0, MAX_TOP_LANGS);
    const other_langs = this._languages.slice(MAX_TOP_LANGS + 1);
    console.log(top_langs, other_langs);
    this.topLangList.update(top_langs);
  }

  // Sort languages descending by total XP
  _sortLangs() {
    this._languages.sort((a, b) => b.xp - a.xp);
  }
}

export default TopLanguagesComponent;
