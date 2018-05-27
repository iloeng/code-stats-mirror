import { wait_for_load } from "../common/utils";
import CookieNoticeComponent from '../common/cookie-notice.component';
import { mount, setChildren } from 'redom';

/**
 * Code that's run on every page.
 */
async function common_run() {
  await wait_for_load();

  const cn_container = document.getElementById('cookie-notice-container');

  if (!CookieNoticeComponent.isCookieNoticeAccepted()) {
    const cnc = new CookieNoticeComponent(() => {
      setChildren(cn_container, []);
    });

    mount(cn_container, cnc);
  }
}

export default common_run;
