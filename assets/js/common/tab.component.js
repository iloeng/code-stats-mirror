import { el } from 'redom';

class TabComponent {
  constructor(tabs, tab_container_id) {
    this.id = `tab-component-for-${tab_container_id}`;

    this.tabEls = tabs.map(([id, text]) => {
      const title = `Click to view tab '${text}'`;
      return el(
        'li',
        {
          id: this._id2TabId(id),
          'aria-label': title,
          title: title,
          role: 'button',
          tabindex: '0',
          'aria-controls': tab_container_id,
          onclick: () => this._click(id),
          onkeydown: e => {
            if (e.keyCode === 13 || e.keyCode === 32) {
              this._click(id);
            }
          }
        },
        text
      );
    });

    this.ids = tabs.map(([id]) => id);

    this.el = el('ul.tabs', { id: this.id }, this.tabEls);
  }

  onmount() {
    this._hideTabs();

    let to_show = window.sessionStorage.getItem(this.id);

    if (to_show == null) {
      to_show = this.ids[0];
    }

    this._showTab(to_show);
  }

  _hideTabs() {
    for (const id of this.ids) {
      document.getElementById(id).style.display = 'none';

      const tab = document.getElementById(this._id2TabId(id));
      tab.classList.remove('active');
      tab.setAttribute('aria-selected', 'false');
    }
  }

  _showTab(id) {
    const tab_contents = document.getElementById(id);
    tab_contents.style.display = 'block';
    tab_contents.focus();

    const tab = document.getElementById(this._id2TabId(id))
    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');

    window.sessionStorage.setItem(this.id, id);
  }

  _click(clicked_id) {
    this._hideTabs();
    this._showTab(clicked_id);
  }

  _id2TabId(id) {
    return `tab-${id}`;
  }
}

export default TabComponent;
