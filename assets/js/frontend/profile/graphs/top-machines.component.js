import { el, list } from 'redom';
import CombinedLevelProgressComponent from '../../graphs/combined-level-progress.component';

class TopMachinesComponent {
  constructor() {
    this.progressList = list('div', CombinedLevelProgressComponent, null, ['p']);

    this.el = el('section.top-machines', [
      el('h4', 'Machines'),
      this.progressList,
    ]);

    this._machines = [];
  }

  setInitData({ total_machines, recent_machines }) {
    for (const { name, xp } of total_machines) {
      this._updateMachine(name, l => {
        l.xp = xp;
        return l;
      });
    }

    for (const { name, xp } of recent_machines) {
      this._updateMachine(name, l => {
        l.recent_xp = xp;
        return l;
      });
    }

    this._sortMachines();
    this.progressList.update(this._machines);
  }

  update({ machine, new_xp }) {
    this._updateMachine(machine, m => {
      m.xp += new_xp;
      m.recent_xp += new_xp;
      return m;
    });

    this._sortMachines();
    this.progressList.update(this._machines);
  }

  // Update a single machine with the given operation
  _updateMachine(name, update_fun) {
    const idx = this._machines.findIndex(l => l.name === name);

    if (idx === -1) {
      const machine = update_fun({ name, xp: 0, recent_xp: 0 });
      this._machines.push(machine);
    }
    else {
      const machine = update_fun(this._machines[idx]);
      this._machines.splice(idx, 1, machine);
    }
  }

  // Sort machines descending by total XP
  _sortMachines() {
    this._machines.sort((a, b) => b.xp - a.xp);
  }
}

export default TopMachinesComponent;
