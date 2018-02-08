import sourcemaps from 'rollup-plugin-sourcemaps';
import resolve from 'rollup-plugin-node-resolve';
import babel from 'rollup-plugin-babel';
import commonjs from 'rollup-plugin-commonjs';

export default {
  plugins: [
    sourcemaps(),
    resolve(),
    babel(),
    commonjs({
      namedExports: {
        'deps/phoenix/priv/static/phoenix.js': ['Socket']
      }
    })
  ]
};
