import { el, setChildren } from 'redom';
import TabComponent from '../../common/tab.component';

const TERMS_API_PATH = '/api/tos';

class OldTermsComponent {
  constructor() {
    this.diffEl = document.getElementById('old-terms-diff');

    this.tabs = new TabComponent([
      ['current-terms', 'New legal terms'],
      ['old-terms-diff', 'Difference from last accepted version']
    ], 'terms-stripe');
    this.el = el('div#old-terms', [this.tabs]);
  }

  onmount() {
    this._colorDiff();
  }

  // Go through diff and mark lines so they can be colored with CSS
  _colorDiff() {
    const text = this.diffEl.textContent.split('\n');
    this.diffEl.textContent = '';

    const elems = text.map(str => {
      if (str.startsWith('+')) {
        return el('p.diff-added', str);
      }
      else if (str.startsWith('-')) {
        return el('p.diff-removed', str);
      }
      else {
        return el('p', str);
      }
    });

    setChildren(this.diffEl, elems);
  }
}

export default OldTermsComponent;
