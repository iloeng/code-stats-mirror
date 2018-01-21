import {el} from 'redom';

const S = Math.sin;
const C = Math.cos;
const T = Math.tan;

function R(r, g, b, a) {
  a = a === undefined ? 1 : a;
  return "rgba("+(r|0)+","+(g|0)+","+(b|0)+","+a+")";
}

// Canvas
let c = null;

// Canvas 2D context
let x = null;

/**
 * Loading indicators from Dwitter.
 *
 * NOTE: These indicators are used with the permission of their respective owners. THEY DO NOT FALL UNDER THE LICENSE
 * OF THE MAIN CODEBASE AND THEY REMAIN COPYRIGHTED TO THEIR CREATORS.
 */
const INDICATORS = [
  {
    author: 'Xen',
    url: 'https://www.dwitter.net/d/6076',
    f: t => { let X, Y; x.beginPath(X=1e3-C(t/5)*799,Y=500+S(t+S(t/3))*299),x.fill(x.arc(X,Y,99,0,7)),x.arc(X,Y,99,0,7),x.stroke(),x.fillStyle=`hsl(${t*9},90%,30%)`; }
  },
  {
    author: 'Xen',
    url: 'https://www.dwitter.net/d/5514',
    f: t => {
      let X, Y, Z;
      X=(C(t**9)+1)/2;
      Y=Math.random();
      x.fillRect(X*900,t*99%1e3,Z=29,Z);
      x.fillRect(1920-Y*900,t*99%1e3,Z,Z);
      x.fillStyle=`hsla(${t*Z},99%,40%,.5)`;
    }
  },
  {
    author: 'Xen',
    url: 'https://www.dwitter.net/d/4848',
    f: t => { let Y, i, X; x.globalCompositeOperation='xor',Y=c.width=99;for(i=2e4;i--;)x.fillRect(i%Y,i/Y,X=S(i-C(t)*Y)-1,X*S(X*t)) }
  },
  {
    author: 'Xen',
    url: 'https://www.dwitter.net/d/4997',
    f: t => { let a; for(c.width=a=99;--a;x.arc(47+C(a+t*9),25+S(a+t*8),a,-t,0));x.fill('evenodd'); }
  },
  {
    author: 'Xen',
    url: 'https://www.dwitter.net/d/4723',
    f: t => {
      let W, H;
      x.strokeRect(3,4,W=1912,H=1072);
      x.drawImage(c,4,4,W,H);
      x.strokeStyle=`hsl(${t*H/9},99%,50%)`;
      x.rotate(C(t)/1e4);
    }
  },
];

class LoadingIndicatorComponent {
  constructor() {
    this.indicator = INDICATORS[Math.floor(Math.random() * INDICATORS.length)];

    this.canvas = c = el('canvas#loading-profile', {width: 1920, height: 1080});
    this.el = el('div.loading-indicator', [
      el('div.canvas-wrapper', [this.canvas]),
      el('span.loading-text', 'Loading data…'),
      el('span.loading-author', [
        el('a', { href: this.indicator.url, target: '_blank' }, `Animation © ${this.indicator.author}`)
      ])
    ]);

    this.initIndicator();
  }

  initIndicator() {
    x = this.canvas.getContext("2d");
    let time = 0;
    let frame = 0;
    const u = t => this.indicator.f(t);

    function loop() {
      time = frame / 60;

      if (time * 60 | 0 == frame - 1) {
        time += 0.000001;
      }

      ++frame;

      try {
        u(time);
      } catch (e) {
        console.error('Error in loading indicator', e);
        return;
      }

      requestAnimationFrame(loop);
    }

    requestAnimationFrame(loop);
  }
}

export default LoadingIndicatorComponent;
