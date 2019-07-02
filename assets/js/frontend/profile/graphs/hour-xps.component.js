import { el, setAttr, svg } from 'redom';
import Chart from 'chart.js';
import { XP_FORMATTER } from '../../../common/xp_utils';


class HourXpsComponent {

  constructor() {
    this.canvas = el('canvas');

    this.chartStyle = localStorage.getItem('HourXpsChartStyle');
    if (!this.chartStyle) this.chartStyle = "clock";

    const clockDrawing = svg('svg',
      svg('symbol', { id: 'clock', viewBox: '-4 -4 16 16', height: 32, width: 32 },
        svg('path', { d: "M4 0c-2.2 0-4 1.8-4 4s1.8 4 4 4 4-1.8 4-4-1.8-4-4-4zm0 1c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm-.5 1v2.22l.16.13.5.5.34.38.72-.72-.38-.34-.34-.34v-1.81h-1z" })
      ),
      svg('use', { xlink: { href: '#clock' } })
    );

    const barDrawing = svg('svg',
      svg('symbol', { id: 'bar', viewBox: '-4 -4 16 16', height: 32, width: 32 },
        svg('path', { d: "M0 0v7h8v-1h-7v-6h-1zm5 0v5h2v-5h-2zm-3 2v3h2v-3h-2z" })
      ),
      svg('use', { xlink: { href: '#bar' } })
    );

    this.clockButton = el('button' + (this.chartStyle == 'clock' ? '.button-pressed' : ''), clockDrawing);
    this.barButton = el('button' + (this.chartStyle == 'bar' ? '.button-pressed' : ''), barDrawing);

    var that = this;
    this.clockButton.onclick = function () {
      that.changeChartStyle('clock');
      that.chart.update();
    }

    this.barButton.onclick = function () {
      that.changeChartStyle('bar');
      that.chart.update();
    }

    this.title = el('h4', [
      'Total XP per hour of days',
      this.clockButton,
      this.barButton,
    ]);

    this.el = el('div.hour-xps', [
      this.title,
      el('div.graph-container', [this.canvas])
    ]);

    this.initializeData();
    
  }


  changeChartStyle(style) {
    if (this.chartStyle == style) return;
    this.chartStyle = style;
    localStorage.setItem('HourXpsChartStyle', style);
    if (this.chartStyle == 'clock') {
      setAttr(this.clockButton, { className: 'button-pressed' })
      setAttr(this.barButton, { className: '' })
      this.chart.destroy();
      this.createClockChart();
    } else {
      setAttr(this.clockButton, { className: '' })
      setAttr(this.barButton, { className: 'button-pressed' })
      this.chart.destroy();
      this.createBarChart();
    }
  }

  initializeData() {
    this.amData = new Array(12).fill(0);
    this.pmData = new Array(12).fill(0);
  }

  createBarChart() {
    const canvas_ctx = this.canvas.getContext('2d');
    this.chart = new Chart(
      canvas_ctx,
      {
        data: {
          labels: [...Array(24).keys()], //.map(function(z) { return z+":00"}),
          datasets: [{
            data: [...this.amData, ...this.pmData],
            backgroundColor: [...Array(24)].map((_, i) => ['rgba(255, 200, 64, 0.5)', 'rgba(10, 0, 178, 0.5)']).flat(),
            borderWidth: 1
          }]
        },
        type: 'bar',
        options: {
          legend: {
            display: false
          },
          tooltips: {
            mode: 'index',
            callbacks: {
              label: (tooltip_item, data) => {
                const label = parseInt(tooltip_item['xLabel']);
                return `${label}:00–${label + 1}:00: ${XP_FORMATTER.format(tooltip_item.yLabel)}`;
              }
            }
          },
          scales: {
            yAxes: [
              {
                ticks: {
                  callback: function (label, index, labels) {
                    return label / 1000 + 'k';
                  }
                },
                scaleLabel: {
                  display: true,
                  labelString: '1k = 1000'
                }
              }
            ]
          }
        }
      }
    );
  }

  createClockChart() {
    const canvas_ctx = this.canvas.getContext('2d');
    this.chart = new Chart(
      canvas_ctx,
      {
        data: {
          datasets: [
            {
              labels: [...Array(12).keys()].map(i => (i + 12).toString()),
              data: this.pmData,
              backgroundColor: 'rgba(255, 200, 64, 0.5)'
            },
            {
              labels: [...Array(12).keys()].map(i => i.toString()),
              data: this.amData,
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
  }

  setInitData({ hour_of_day_xps }) {
    console.log("SET INIT DATA")
    const hod_items = Object.entries(hour_of_day_xps).map(([hour, xps]) => [parseInt(hour), xps]);
    hod_items.sort(([hour1], [hour2]) => hour1 - hour2);

    for (const [hour, xps] of hod_items) {
      this._insertIntoHour(hour, xps);
    }
    
    if (this.chartStyle == 'clock') {
      this.createClockChart();
    } else {
      this.createBarChart();
    }
    this.chart.update();
  }

  update({ new_xp, sent_at_local }) {
    console.log("UPDATE")
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
