import { el } from 'redom';

const COOKIE_NOTICE_KEY = 'code_stats_cookie_notice_shown';

class CookieNoticeComponent {
  constructor(close_callback) {
    this.closeCallback = close_callback;

    const close_el = el('button', { class: 'button-info' }, 'Close');
    close_el.addEventListener('click', () => this.closeClicked());

    this.el = el('div#cookie-notice', [
      el(
        'p',
        [
          el('span', 'This website uses features such as cookies and local storage to function. In addition, the analytics provider may use similar technologies to track user sessions. Please see our '),
          el('a', { href: '/tos', target: '_blank' }, 'privacy policy'),
          el('span', ' for more information.')
        ]
      ),
      close_el
    ]);
  }

  closeClicked() {
    window.localStorage.setItem(COOKIE_NOTICE_KEY, 'true');
    this.closeCallback();
  }

  static isCookieNoticeAccepted() {
    return window.localStorage.getItem(COOKIE_NOTICE_KEY) === 'true';
  }
}

export default CookieNoticeComponent;
