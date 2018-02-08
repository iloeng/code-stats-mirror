// Polyfills for crappy browsers. This will be replaced by babel-preset-env to the minimal set required
import 'babel-polyfill';

import Router from './router';

const router = new Router();
router.execute();
