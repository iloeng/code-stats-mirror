import { el } from 'redom';
import { get_level, XP_FORMATTER } from '../../common/xp_utils';

class LevelCounterComponent {
  constructor(element_type, prefix, total_xp, new_xp) {
    this.totalXp = total_xp;
    this.newXp = new_xp;
    this.level = 0;
    this.prefixEl = null;
    this.contentEl = el('span.total-xp');
    this.postfixEl = el('span.recent-xp');

    if (prefix != null) {
      this.prefixEl = el('strong.level-prefix', prefix);
    }

    this.el = el(
      `${element_type}.level-counter`,
      [
        (this.prefixEl != null) && this.prefixEl,
        this.contentEl,
        this.postfixEl
      ]
    );

    this._refresh();
  }

  update(total_xp, new_xp, prefix = null) {
    this.totalXp = total_xp;
    this.newXp = new_xp;

    if (prefix != null) {
      this.prefixEl.textContent = prefix;
    }

    this._refresh();
  }

  _refresh() {
    this.level = get_level(this.totalXp);

    let title = ` level ${this.level} (${XP_FORMATTER.format(this.totalXp)} XP)`;
    let postfix = '';

    if (this.prefixEl == null) {
      title = title.charAt(1).toUpperCase() + title.slice(2);
    }

    if (this.newXp > 0) {
      postfix = ` (+${XP_FORMATTER.format(this.newXp)})`;
    }

    this.contentEl.textContent = title;
    this.postfixEl.textContent = postfix;
  }
}

export default LevelCounterComponent;
