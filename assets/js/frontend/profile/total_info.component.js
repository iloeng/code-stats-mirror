import {el, mount, unmount, setChildren, text} from 'redom';
import LevelCounterComponent from '../graphs/level_counter.component';
import ProgressBarComponent from '../graphs/progress_bar.component';

import {DateTime} from 'luxon';

/**
 * Renders the profile information and total XP of the user.
 */
class TotalInfoComponent {
  constructor(init_el, total_xp, new_xp, username) {
    this.totalXp = total_xp;
    this.newXp = new_xp;
    this.username = username;

    this.registeredAt = DateTime.fromISO(document.getElementById('registered-at').getAttribute('datetime'));

    const last_day_coded_el = document.getElementById('last-programmed-at');
    this.lastDayCoded = null;

    if (last_day_coded_el != null) {
      this.lastDayCoded = DateTime.fromISO(last_day_coded_el.getAttribute('datetime'));
    }

    this.usernameEl = el('h1#profile-username', {'data-name': this.username}, this.username);

    this.lastProgrammedEl = el('li', this._getLastProgrammedElems());

    this.profileDetailList = el('ul#profile-detail-list', [
      el('li', [
        'User since ',
        this._getDateEl(this.registeredAt),
        '.'
      ]),
      this.lastProgrammedEl
    ]);

    this.levelCounter = new LevelCounterComponent('h2', null, this.totalXp, this.newXp);
    this.progressBar = new ProgressBarComponent(this.totalXp, this.newXp);

    this.totalProgress = el('div#total-progress', [this.levelCounter, this.progressBar]);

    setChildren(init_el, []);
    mount(init_el, this.usernameEl);
    mount(init_el, this.profileDetailList);
    mount(init_el, this.totalProgress);
  }

  setInitData({total_langs, recent_langs}) {
    if (total_langs != null) {
      this.totalXp = total_langs.reduce((total, {xp}) => total += xp, 0);
    }

    if (recent_langs != null) {
      this.newXp = recent_langs.reduce((total, {xp}) => total += xp, 0);
    }

    this._updateChildren();
  }

  update({xps, sent_at_local}) {
    let new_xp = xps.reduce((acc, {amount}) => acc + amount, 0);

    this.totalXp += new_xp;
    this.newXp += new_xp;

    this.lastDayCoded = DateTime.fromISO(sent_at_local);
    setChildren(this.lastProgrammedEl, this._getLastProgrammedElems());

    this._updateChildren();
  }

  _updateChildren() {
    this.levelCounter.update(this.totalXp, this.newXp);
    this.progressBar.update(this.totalXp, this.newXp);
  }

  _formatDate(date) {
    return date.toFormat('LLL d, yyyy');
  }

  _getDateEl(date) {
    return el('time', this._formatDate(date), {datetime: date.toISODate()});
  }

  _getLastProgrammedElems() {
    return el('li', [
      text('Last programmed '),
      (this.lastDayCoded != null) && this._getDateEl(this.lastDayCoded),
      (this.lastDayCoded == null) && el('em', 'never'),
      text('.')
    ]);
  }
}

export default TotalInfoComponent;
