import {el, mount, setChildren} from 'redom';
import LoadingIndicatorComponent from '../../../common/js/loading-indicator.component';

class MainInfoComponent {
  constructor(init_element) {
    this.el = el('div', [
      new LoadingIndicatorComponent()
    ]);
  }

  initData(data) {
    setChildren(this.el, []);
  }

  update(data) {

  }
}

export default MainInfoComponent;
