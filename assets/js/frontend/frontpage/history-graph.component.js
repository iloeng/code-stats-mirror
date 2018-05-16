import { el } from 'redom';
import Chart from 'Chart.js';
import { DateTime } from 'luxon';

/**
 * Max XP per single group, to smoothen out the graph from impossible peaks.
 */
const MAX_EVENT_VAL = 20000;

// These MUST match the values in XPHistoryCache for the graph to be rendered properly!
const HISTORY_HOURS = 4;
const GROUP_MINUTES = 1;

// How often to check if a new bar should appear, in seconds
const UPDATE_INTERVAL = 10;

class HistoryGraphComponent {
  constructor() {
    this.el = el('canvas');
    this.chart = new Chart(
      this.el.getContext('2d'),
      {
        type: 'bar',
        data: {
          labels: [],
          datasets: [{
            label: 'Global XP',
            data: [],
            backgroundColor: '#9699b0'
          }]
        },
        options: {
          legend: {
            display: false
          },
          tooltips: {
            enabled: true,
            displayColors: false
          },
          scales: {
            xAxes: [{
              display: false,
              barPercentage: 1,
              categoryPercentage: 1
            }],
            yAxes: [{
              display: false
            }]
          },
          maintainAspectRatio: false
        }
      }
    );

    this.dataset = this.chart.data.datasets[0];
    this.newestTime = null;

    this.interval = setInterval(() => this._checkMove(), UPDATE_INTERVAL * 1000);
  }

  init({ xp_history: data }) {
    data = this._mapTimes(data);
    data = this._transformData(data);
    this.dataset.data = data;

    // Generate empty labels for the whole dataset
    this.chart.data.labels = Array(data.length).fill('');

    this.chart.update();
  }

  addPulse(amount) {
    this.dataset.data[this.dataset.data.length - 1] += amount;
    this.chart.update();
  }

  // Check if data should be moved to the left and a new bar added
  _checkMove() {
    // If data isn't retrieved yet, don't do anything
    if (this.newestTime == null) return;

    const now = DateTime.utc();

    if (now.diff(this.newestTime, 'minutes').minutes >= GROUP_MINUTES) {
      this.dataset.data.shift();
      this.dataset.data.push(0);

      this.chart.update(0);

      this.newestTime = now;
    }
  }

  _mapTimes(data) {
    const ret = data.map(
      ([[[year, month, day], [hour, minute]], xp]) => [DateTime.utc(year, month, day, hour, minute), xp]
    );

    ret.sort((a, b) => {
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    });

    return ret;
  }

  // Fill empty slots in the data with zeroes and drop the keys
  _transformData(data) {
    const now = DateTime.utc();
    const start_minute = Math.floor(now.get('minute') / GROUP_MINUTES) * GROUP_MINUTES;
    const start = now.minus({ hours: HISTORY_HOURS }).set({ minute: start_minute, second: 0 });

    let time = start;
    const inc_time = t => t.plus({ minutes: GROUP_MINUTES });

    const ret = data.reduce((acc, [data_time, xp]) => {
      // Skip all times that don't fit the range
      if (data_time < start) {
        return acc;
      }

      while (time < data_time) {
        acc.push(0);
        time = inc_time(time);
      }

      // Max bound for XP per event to look more even
      xp = Math.min(xp, MAX_EVENT_VAL);

      acc.push(xp);
      time = inc_time(data_time);
      return acc;
    }, []);

    // Fill the rest of the time range if needed
    while (time < now) {
      ret.push(0);
      time = inc_time(time);
    }

    this.newestTime = now;
    return ret;
  }
}

export default HistoryGraphComponent;
