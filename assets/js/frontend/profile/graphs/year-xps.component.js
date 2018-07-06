import { el, list } from 'redom';
import { DateTime } from 'luxon';
import { ACCENT_COLOR, BACKGROUND_COLOR, TEXT_COLOR, ACCENT_TEXT, ACCENT_TEXT_FLIP_PERCENT } from '../../config';
import { hex_to_color, color_to_rgb_str } from '../../../common/utils';
import { LOCALE } from '../../../common/config';
import { XP_FORMATTER } from '../../../common/xp_utils';

// Year to use when simulating a leap year
const YEAR = 2000;

const MONTHS = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Today's date, calculated every n seconds to show user which day it is
let today = null;

// Timer seconds for the aforementioned
const TODAY_UPDATE_SECONDS = 60;

class YearXpsTableHeadingComponent {
  constructor() {
    this.el = el('th');
  }

  update(day) {
    this.el.textContent = day;
  }
}

const MAX_COLOR = hex_to_color(ACCENT_COLOR);
const MIN_COLOR = hex_to_color(BACKGROUND_COLOR);
const MAX_TEXT_COLOR = hex_to_color(ACCENT_TEXT);
const MIN_TEXT_COLOR = hex_to_color(TEXT_COLOR);

const CELL_FORMATTER = new Intl.NumberFormat(LOCALE, {
  maximumFractionDigits: 0,
});

class YearXpsTableCellComponent {
  constructor() {
    this.el = el('td');
  }

  update(data, index, items, max_val) {
    if (index === 0) {
      // For first column, just print the month name
      this.el.textContent = data;
      this.el.classList.add('month-td');
    }
    else {
      const { date, xp } = data;
      this.el.textContent = this._formatValue(xp);
      this._setSmallClass();
      this._setTodayClass(date);

      const max_scale = xp / max_val;

      const scale_color = c => Math.round(MIN_COLOR[c] + ((MAX_COLOR[c] - MIN_COLOR[c]) * max_scale));

      const bg_color = { r: scale_color('r'), g: scale_color('g'), b: scale_color('b') };
      this.el.style.backgroundColor = color_to_rgb_str(bg_color);

      if (max_scale * 100 > ACCENT_TEXT_FLIP_PERCENT) {
        this.el.style.color = color_to_rgb_str(MAX_TEXT_COLOR);
      }
      else {
        this.el.style.color = color_to_rgb_str(MIN_TEXT_COLOR);
      }

      this.el.title = `${MONTHS[date.month - 1]} ${date.day}: ${XP_FORMATTER.format(xp)} XP`;
    }
  }

  // Attempt to format value to max 3 chars + unit
  _formatValue(value) {
    if (value < 1000) {
      return value.toString();
    }
    else if (value < 1000000) {
      return CELL_FORMATTER.format(value / 1000) + 'k';
    }
    else {
      return CELL_FORMATTER.format(value / 1000000) + 'M';
    }
  }

  // Set .small class if text is wide
  _setSmallClass() {
    if (this.el.textContent.length >= 4) {
      this.el.classList.add('small');
    }
    else {
      this.el.classList.remove('small');
    }
  }

  // Set .today class if cell date is today
  _setTodayClass(date) {
    if (date.month === today.month && date.day === today.day) {
      this.el.classList.add('today');
    }
    else {
      this.el.classList.remove('today');
    }
  }
}

class YearXpsTableRowComponent {
  constructor() {
    this.data = {};

    this.el = list('tr', YearXpsTableCellComponent);
  }

  update(data, index, items, max_val) {
    this.data = data;
    this.el.update(this.data.days, max_val);
  }
}

class YearXpsComponent {
  constructor() {
    // XP by day of year
    this.xpByDay = {};

    // Data model for month list
    this.data = [...Array(12).keys()].map(i => {
      return { month: i, days: [MONTHS[i]] };
    });

    this.todayUpdateTimer = null;

    this.headerList = list('tr', YearXpsTableHeadingComponent);
    this.months = list('tbody', YearXpsTableRowComponent);

    this.el = el('section.year-xps', [
      el('h4', 'Total XP by day of year'),
      el('div.table-container',
        el('table', [
          el('thead', [this.headerList]),
          this.months,
        ])
      ),
    ]);
    this.headerList.update([null, ...(Array.from(new Array(31), (_, i) => i + 1))]);
  }

  onmount() {
    this._updateToday(false);
    this.todayUpdateTimer = setInterval(() => this._updateToday(), TODAY_UPDATE_SECONDS * 1000);
  }

  onunmount() {
    if (this.todayUpdateTimer != null) {
      clearInterval(this.todayUpdateTimer);
    }
  }

  setInitData({ day_of_year_xps }) {
    this.xpByDay = day_of_year_xps;
    const max_val = this._findMaxXP();
    for (const ord of Object.keys(this.xpByDay)) {
      const date = DateTime.fromObject({ ordinal: parseInt(ord), year: YEAR });
      this.data[date.month - 1]['days'][date.day] = { date, xp: this.xpByDay[ord] };
    }

    this.months.update(this.data, max_val);
  }

  update({ new_xp, sent_at_local }) {
    const ord = sent_at_local.ordinal;
    this.xpByDay[ord] += new_xp;
    const max_val = this._findMaxXP();

    this.data[sent_at_local.month - 1]['days'][sent_at_local.day].xp += new_xp;
    this.months.update(this.data, max_val);
  }

  _findMaxXP() {
    let max_val = 0;
    for (const ord of Object.keys(this.xpByDay)) {
      const xp = this.xpByDay[ord];
      if (xp > max_val) {
        max_val = xp;
      }
    }

    return max_val;
  }

  _updateToday(run_update = true) {
    today = DateTime.local().startOf('day');

    if (run_update) {
      this.update({ new_xp: 0, sent_at_local: DateTime.local() })
    }
  }
}

export default YearXpsComponent;
