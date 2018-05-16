import sourcemaps from 'rollup-plugin-sourcemaps';
import resolve from 'rollup-plugin-node-resolve';
import babel from 'rollup-plugin-babel';
import commonjs from 'rollup-plugin-commonjs';
import analyze from 'rollup-analyzer-plugin';

const analyze_opts = { limit: 5 };

export default {
  // Chart.js wants to import Moment, but we won't let it since we are using Luxon. This means we can't use the time
  // scale in the charts since it needs Moment.
  external: ['moment'],
  plugins: [
    analyze(analyze_opts),
    sourcemaps(),
    resolve(),
    commonjs({
      namedExports: {
        'deps/phoenix/priv/static/phoenix.js': ['Socket']
      }
    }),
    babel({
      exclude: ['**/node_modules/**', '**/deps/phoenix/**'],
      presets: [
        [
          'env',
          {
            targets: {
              browsers: [
                'last 2 Chrome versions',
                'last 2 Edge versions',
                'last 2 Safari versions',
                'last 2 Firefox versions',
                'last 2 and_chr versions',
                'last 2 and_ff versions',
                'last 2 ios_saf versions'
              ]
            },
            useBuiltIns: true,
            modules: false
          }
        ]
      ],
      plugins: [
        'external-helpers'
      ],
      babelrc: false
    }),
  ]
};
