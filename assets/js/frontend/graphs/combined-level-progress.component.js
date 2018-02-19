import {el} from 'redom';
import LevelCounterComponent from './level_counter.component';
import ProgressBarComponent from './progress_bar.component';

/**
 * Shows a level progress title and a progress bar under it.
 */
class CombinedLevelProgressComponent {
  constructor(title_element_type) {
    this._levelCounter = new LevelCounterComponent(title_element_type, '', 0, 0);
    this._progressBar = new ProgressBarComponent(0, 0);

    this.el = el('div.combined-level-progress', [
      this._levelCounter,
      this._progressBar,
    ]);
  }

  update({name, xp, recent_xp}) {
    this._levelCounter.update(xp, recent_xp, name);
    this._progressBar.update(xp, recent_xp);
  }
}

export default CombinedLevelProgressComponent;
