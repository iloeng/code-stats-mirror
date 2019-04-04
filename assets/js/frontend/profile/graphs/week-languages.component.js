import { el } from 'redom';
import Chart from 'chart.js';
import { get_graph_color } from '../../../common/graph-colors';
import { Interval } from 'luxon';
import { XP_FORMATTER } from '../../../common/xp_utils';
import { SMALL_BREAKPOINT } from '../../../common/config';

/** Maximum amount of languages to show, grouping others under "Other". */
const MAX_LANGS = 8;

class WeekLanguagesComponent {
  constructor(start_date, end_date) {
    this.startDate = start_date;
    this.endDate = end_date;

    this.canvas = el('canvas');
    this.el = el('section.week-languages', [
      //el('h4', 'Daily progress during last 14 days'),
      el('div.graph-container', [this.canvas]),
    ]);

    this.chart = new Chart(
      this.canvas.getContext('2d'),
      {
        type: 'bar',
        data: {
          labels: [],
          datasets: []
        },
        options: {
          legend: {
            display: true,
            position: 'right',
          },
          tooltips: {
            enabled: true,
            displayColors: true,
            mode: 'x',
            // Filter out 0-languages from tooltip
            filter: i => { return !isNaN(i.yLabel); },
            callbacks: {
              // Format tooltip labels as XP
              label: (tooltip_item, data) => {
                const label = data.datasets[tooltip_item.datasetIndex].label || '';
                return `${label}: ${XP_FORMATTER.format(tooltip_item.yLabel)}`;
              }
            }
          },
          scales: {
            xAxes: [{
              stacked: true,
            }],
            yAxes: [{
              stacked: true,
              scaleLabel: {
                display: true,
                labelString: 'XP',
              },
              ticks: {
                callback: val => XP_FORMATTER.format(val)
              }
            }]
          },
          maintainAspectRatio: false,
          onResize: (chart, { width }) => {
            if (width < SMALL_BREAKPOINT) {
              chart.options.legend.display = false;
            }
            else {
              chart.options.legend.display = true;
            }
          }
        }
      }
    );

    this.labels = this.chart.data.labels;
    this.datasets = this.chart.data.datasets;

    // Mapping from language to index in dataset, if language is not in map then it should be added to
    // "others" dataset
    this._langDatasetMapping = new Map();
  }

  setInitData({ day_language_xps }) {
    this.labels.length = 0;
    this.datasets.length = 0;

    // Sort ascending by date, ISO date is sortable as string
    day_language_xps = day_language_xps.slice().sort(({ date: d1 }, { date: d2 }) => {
      if (d1 > d2) return 1;
      if (d2 < d1) return -1;
      return 0;
    });

    const all_top_langs = day_language_xps.reduce((acc, { language, xp }) => {
      if (language in acc) {
        acc[language] += xp;
      }
      else {
        acc[language] = xp;
      }

      return acc;
    }, {});

    const atl_entries = Object.entries(all_top_langs);
    atl_entries.sort(([, x1], [, x2]) => x2 - x1);
    atl_entries.slice(0, MAX_LANGS).forEach(([l,]) => this._createDataset(l));

    // Shift start and end dates to match beginning and end of days
    const real_start = this.startDate.startOf('day');
    const real_end = this.endDate.endOf('day');

    const interval = Interval.fromDateTimes(real_start, real_end);
    // Dates in this graph are all the days in the startDate-endDate interval, use them as labels.
    // Slice one day off the start to avoid off-by-one errors (getting 1 day too many).
    const dates = interval.splitBy({ days: 1 }).map(i => i.start).slice(1);
    dates.forEach(d => this.labels.push(this._dateToLabel(d)));

    // Form lookup table of dates to indexes so data can be inserted in the correct spot in the dataset arrays
    const date_lookup = dates.reduce((acc, date, idx) => {
      acc[date.toISODate()] = idx;
      return acc;
    }, {});

    // Loop through data and insert into datasets in the correct places
    for (const { language, date, xp } of day_language_xps) {
      const dataset = this._getDataset(language);
      if (date in date_lookup) {
        const idx = date_lookup[date];
        dataset.data[idx] = xp;
      }
    }

    this.chart.update();
  }

  update({ sent_at_local, xps }) {
    let days_added = false;

    // Use date string comparison to avoid problems with comparing across timezones, we just need to know if
    // the date sent is newer than the latest displayed date on the graph.
    const sent_at_date = sent_at_local.toISODate();
    while (sent_at_date > this.endDate.toISODate()) {
      this._addDay();
      days_added = true;
    }

    for (const { language, amount } of xps) {
      const dataset = this._getDataset(language);
      const label = this._dateToLabel(sent_at_local);
      const idx = this.labels.findIndex(dt => dt === label);

      if (!isNaN(dataset.data[idx])) {
        dataset.data[idx] += amount;
      }
      else {
        dataset.data[idx] = amount;
      }
    }

    if (days_added) {
      // Don't animate if days were added to avoid looking silly when data is shifted to the left by a day
      this.chart.update(0);
    }
    else {
      this.chart.update();
    }
  }

  // Get or create dataset for give language, using "Others" dataset if appropriate
  _getDataset(lang) {
    if (this._langDatasetMapping.has(lang)) {
      return this.datasets[this._langDatasetMapping.get(lang)];
    }
    else if (this.datasets.length > MAX_LANGS) {
      return this.datasets[MAX_LANGS];
    }
    else {
      return this._createDataset(lang);
    }
  }

  // Create a new dataset for given language, possible "Others" dataset
  _createDataset(lang) {
    let label = lang;

    if (this._langDatasetMapping.size >= MAX_LANGS) {
      label = 'Others';
    }

    const length = this.datasets.push({
      data: [],
      backgroundColor: get_graph_color(this.datasets.length),
      label
    });

    if (this._langDatasetMapping.size < MAX_LANGS) {
      this._langDatasetMapping.set(lang, length - 1);
    }

    return this.datasets[length - 1];
  }

  // Add a single day to the graph, removing the oldest day
  _addDay() {
    this.endDate = this.endDate.plus({ days: 1 });
    this.startDate = this.startDate.plus({ days: 1 });

    this.labels.shift();
    this.labels.push(this._dateToLabel(this.endDate));

    for (const dataset of this.datasets) {
      dataset.data.shift();
      dataset.data.push(0);
    }
  }

  _dateToLabel(date) {
    return date.toFormat('LLL d');
  }
}

export default WeekLanguagesComponent;
