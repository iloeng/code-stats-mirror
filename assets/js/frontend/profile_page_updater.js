import {mount, setChildren} from 'redom';
import MainInfoComponent from './profile/main_info.component';
import TotalInfoComponent from './profile/total_info.component';
import {request_profile, race_promises} from '../common/utils';
import {DateTime} from 'luxon';

/**
 * Handles connecting to the profile page socket and sending updates to the components.
 */
class ProfilePageUpdater {
  constructor(socket) {
    this.socket = socket;
    this.channel = null;

    // While loading is true, new XP will not be processed
    this.loading = true;

    this.username = document.getElementById('profile-username').dataset.name;
    [this.totalXp, this.newXp] = this._parseTotalProgress();

    // Component containers
    this.tuDiv = document.getElementById('profile-total-container');
    this.muDiv = document.getElementById('main-stats-container');

    // Main components
    this.tuApp = new TotalInfoComponent(this.tuDiv, this.totalXp, this.newXp, this.username);
    this.muApp = new MainInfoComponent();

    setChildren(this.muDiv, []);

    mount(this.muDiv, this.muApp);

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

        if (!this.loading) {
          this.loading = true;
          this.loadBaseData();
        }
      })
      .receive('error', resp => console.error('Connection failed:', resp));

    this.channel.on('new_pulse', msg => this.newPulse(msg));
  }

  async loadBaseData() {
    // Data wanted by both components
    const now = DateTime.utc();
    const since_recent = now.minus({hours: 12});
    const common_spec = {
      total_langs: 'languages {name xp}',
      recent_langs: `languages(since: ${JSON.stringify(since_recent.toISO())}) {name xp}`
    };

    const spec = Object.assign(common_spec, this.muApp.getDataRequest());

    let promises = request_profile(this.username, spec);

    while (promises.length > 0) {
      const [data, new_promises] = await race_promises(promises);

      this.tuApp.setInitData(data);
      this.muApp.setInitData(data);

      promises = new_promises;
    }
  }

  newPulse(msg) {
    this.tuApp.update(msg);
    this.muApp.update(msg);
  }

  _parseTotalProgress() {
    const el = document.getElementById('total-progress');

    return [parseInt(el.dataset.totalXp), parseInt(el.dataset.newXp)];
  }
}

export default ProfilePageUpdater;