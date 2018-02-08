import {el, mount, setChildren} from 'redom';
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
    this.profileDetailList = el('ul#profile-detail-list', [
      el('li', [
        'User since ',
        el('time', this._formatDate(this.registeredAt), {datetime: this.registeredAt}),
        '.'
      ]),
      el('li', [
        'Last programmed ',
        (this.lastDayCoded != null) && el('time', this._formatDate(this.lastDayCoded), {datetime: this.lastDayCoded}),
        (this.lastDayCoded == null) && el('em', 'never'),
        '.'
      ])
    ]);

    this.levelCounter = new LevelCounterComponent('h2', null, this.totalXp, this.newXp);
    this.progressBar = new ProgressBarComponent(this.totalXp, this.newXp);

    this.totalProgress = el('div#total-progress', [this.levelCounter, this.progressBar]);

    setChildren(init_el, []);
    mount(init_el, this.usernameEl);
    mount(init_el, this.profileDetailList);
    mount(init_el, this.totalProgress);
  }

  update({xps}) {
    let new_xp = xps.reduce((acc, {amount}) => acc + amount, 0);

    this.totalXp += new_xp;
    this.newXp += new_xp;

    this._updateChildren();
  }

  _updateChildren() {
    this.levelCounter.update(this.totalXp, this.newXp);
    this.progressBar.update(this.totalXp, this.newXp);
  }

  _formatDate(date) {
    return date.toFormat('LLL d, yyyy');
  }
}

export default TotalInfoComponent;
