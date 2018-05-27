// Polyfills for crappy browsers. This will be replaced by babel-preset-env to the minimal set required
import 'babel-polyfill';

import Router from './router';
import common_run from './common';

common_run();

const router = new Router();
router.execute();
