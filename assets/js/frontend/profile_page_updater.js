import { mount, setChildren } from 'redom';
import MainInfoComponent from './profile/main_info.component';
import TotalInfoComponent from './profile/total_info.component';
import { request_profile, race_promises } from '../common/utils';
import { DateTime } from 'luxon';

import { RECENT_HOURS } from './config';

/**
 * Handles connecting to the profile page socket and sending updates to the components.
 */
class ProfilePageUpdater {
  constructor(socket) {
    this.socket = socket;
    this.channel = null;

    // While loading is true, new XP will not be processed
    this.loading = true;

    // Is this the first connect to socket instead of reconnect?
    this.firstConnect = true;

    this.username = document.getElementById('profile-username').dataset.name;
    [this.totalXp, this.newXp] = this._parseTotalProgress();

    // Component containers
    this.tuDiv = document.getElementById('profile-total-container');
    this.muDiv = document.getElementById('main-stats-container');

    // Main components
    this.tuApp = new TotalInfoComponent(this.tuDiv, this.totalXp, this.newXp);
    this.muApp = new MainInfoComponent(this.totalXp);

    setChildren(this.muDiv, [this.muApp]);

    this.loadBaseData();
    this.initSocket();
  }

  initSocket() {
    this.socket.connect();

    this.channel = this.socket.channel(`users:${this.username}`, {});

    console.log(`Joining channel users:${this.username}…`);
    this.channel.join()
      .receive('ok', () => {
        console.log('Connection successful.');

        // On every (re)connection, fetch latest base data from backend to avoid desync, only then start to accept
        // new pulse data. Unless this is the first connect, as data is loading already when component initialises.
        if (!this.firstConnect) {
          this.loadBaseData();
        }

        this.firstConnect = false;
      })
      .receive('error', resp => console.error('Connection failed:', resp));

    this.channel.on('new_pulse', msg => this.newPulse(msg));
  }

  async loadBaseData() {
    this.loading = true;
    this.muApp.setLoadingStatus(this.loading);

    // Data wanted by both components
    const now = DateTime.utc();
    const since_recent = now.minus({ hours: RECENT_HOURS });
    const common_spec = {
      total_langs: 'languages {name xp}',
      recent_langs: `languages(since: ${JSON.stringify(since_recent.toISO())}) {name xp}`
    };

    const spec = Object.assign(common_spec, this.muApp.getDataRequest());

    request_profile(this.username, spec).then(data => {
      if (this.loading) {
        this.loading = false;
        this.muApp.setLoadingStatus(this.loading);
      }

      this.tuApp.setInitData(data);
      this.muApp.setInitData(data);
    });
  }

  newPulse(msg) {
    // Calculate total and parse datetimes once so don't need to keep recalculating them
    msg.new_xp = msg.xps.reduce((acc, { amount }) => acc + amount, 0);

    msg.sent_at = DateTime.fromISO(msg.sent_at, { setZone: true });
    msg.sent_at_local = DateTime.fromISO(msg.sent_at_local, { setZone: true });

    this.tuApp.update(msg);
    this.muApp.update(msg);
  }

  _parseTotalProgress() {
    const el = document.getElementById('total-progress');

    return [parseInt(el.dataset.totalXp), parseInt(el.dataset.newXp)];
  }
}

export default ProfilePageUpdater;
