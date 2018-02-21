// How many languages to show in top list at maximum
const MAX_TOP_LANGS = 10;

/**
 * Data source for language components to avoid calculating top languages many times.
 */
class LanguagesDataSource {
  constructor(datasource) {
    // Lists of language objects {name, xp, recent_xp}
    this._languages = [];
  }

  setInitData({total_langs, recent_langs}) {
    for (const {name, xp} of total_langs) {
      this._updateLang(name, l => {
        l.xp = xp;
        return l;
      });
    }

    for (const {name, xp} of recent_langs) {
      this._updateLang(name, l => {
        l.recent_xp = xp;
        return l;
      });
    }

    this._sortLangs();
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
  }

  getTopLangs() {
    return this._languages.slice(0, MAX_TOP_LANGS);
  }

  getOtherLangs() {
    return this._languages.slice(MAX_TOP_LANGS + 1);
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

  // Sort languages descending by total XP
  _sortLangs() {
    this._languages.sort((a, b) => b.xp - a.xp);
  }
}

export default LanguagesDataSource;
