import { el } from 'redom';
import Chart from 'chart.js';
import { XP_FORMATTER } from '../../../common/xp_utils';

class HourXpsComponent {
  constructor() {
    this.canvas = el('canvas');
    this.el = el('div.hour-xps', [
      el('h4', 'Total XP per hour of day'),
      el('div.graph-container', [this.canvas])
    ]);

    const canvas_ctx = this.canvas.getContext('2d');

    this.chart = new Chart(
      canvas_ctx,
      {
        data: {
          datasets: [
            {
              labels: [...Array(12).keys()].map(i => (i + 12).toString()),
              data: new Array(12).fill(0),
              backgroundColor: 'rgba(255, 200, 64, 0.5)'
            },
            {
              labels: [...Array(12).keys()].map(i => i.toString()),
              data: new Array(12).fill(0),
              backgroundColor: 'rgba(10, 0, 178, 0.5)'
            }
          ]
        },
        type: 'polarArea',
        options: {
          startAngle: -0.5 * Math.PI,
          legend: {
            display: false
          },
          tooltips: {
            mode: 'index',
            callbacks: {
              // Format tooltip labels as XP
              label: (tooltip_item, data) => {
                const label_str = data.datasets[tooltip_item.datasetIndex].labels[tooltip_item.index];
                const label = parseInt(label_str);
                return `${label}–${label + 1}: ${XP_FORMATTER.format(tooltip_item.yLabel)}`;
              }
            }
          },

          scale: {
            ticks: {
              callback: val => XP_FORMATTER.format(val),
              beginAtZero: true
            }
          }
        },
      }
    );

    this.amData = this.chart.data.datasets[1].data;
    this.pmData = this.chart.data.datasets[0].data;
  }

  setInitData({ hour_of_day_xps }) {
    const hod_items = Object.entries(hour_of_day_xps).map(([hour, xps]) => [parseInt(hour), xps]);
    hod_items.sort(([hour1], [hour2]) => hour1 - hour2);

    for (const [hour, xps] of hod_items) {
      this._insertIntoHour(hour, xps);
    }

    this.chart.update();
  }

  update({ new_xp, sent_at_local }) {
    const hour = sent_at_local.hour;
    this._insertIntoHour(hour, new_xp, true);
    this.chart.update();
  }

  // Insert XP into given hour (0-11 integer), adding instead of replacing if specified
  _insertIntoHour(hour, xps, add = false) {
    const dataset = (hour < 12) ? this.amData : this.pmData;

    if (add) {
      dataset[hour % 12] += xps;
    }
    else {
      dataset[hour % 12] = xps;
    }
  }
}

export default HourXpsComponent;
