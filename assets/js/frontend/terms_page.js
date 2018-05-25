import { wait_for_load } from "../common/utils";
import { mount } from 'redom';
import OldTermsComponent from "./terms/old-terms.component";

/**
 * Code to execute on legal terms page. Shows links to old terms and diffs to current versions.
 */
async function terms_page() {
  await wait_for_load();

  const terms_stripe_el = document.getElementById('terms-tabs');
  mount(terms_stripe_el, new OldTermsComponent());
}

export default terms_page;
