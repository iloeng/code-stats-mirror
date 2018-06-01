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

    /*
    const am_gradient = canvas_ctx.createLinearGradient(0.000, 150.000, 300.000, 150.000);
    am_gradient.addColorStop(0.000, 'rgba(0, 0, 0, 0.5)');
    am_gradient.addColorStop(0.378, 'rgba(10, 0, 178, 0.5)');
    am_gradient.addColorStop(0.761, 'rgba(255, 252, 0, 0.5)');

    const pm_gradient = canvas_ctx.createLinearGradient(0.000, 150.000, 300.000, 150.000);
    pm_gradient.addColorStop(0.000, 'rgba(255, 255, 0, 0.5)');
    pm_gradient.addColorStop(0.136, 'rgba(255, 255, 170, 0.5)');
    pm_gradient.addColorStop(0.381, 'rgba(255, 255, 0, 0.5)');
    pm_gradient.addColorStop(0.663, 'rgba(191, 0, 0, 0.5)');
    pm_gradient.addColorStop(0.888, 'rgba(0, 0, 0, 0.5)');
    */

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
          startAngle: -0.5 * Math.PI - (Math.PI / 12),
          legend: {
            display: false
          },
          tooltips: {
            mode: 'index',
            callbacks: {
              // Format tooltip labels as XP
              label: (tooltip_item, data) => {
                const label = data.datasets[tooltip_item.datasetIndex].labels[tooltip_item.index] || '';
                return `${label}: ${XP_FORMATTER.format(tooltip_item.yLabel)}`;
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
      const dataset = (hour < 12) ? this.amData : this.pmData;
      dataset[hour % 12] = xps;
    }

    this.chart.update();
  }

  update() { }
}

export default HourXpsComponent;
