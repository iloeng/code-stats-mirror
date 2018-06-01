const path = require('path');

const n_path = path.resolve(__dirname, 'node_modules');

module.exports = {
  module: {
    rules: [
      {
        // Chart.js wants moment.js, but we are using Luxon, so remove moment.js from bundle
        test: /(moment\.js)/,
        use: path.resolve(n_path, 'null-loader')
      },
      {
        test: /\.js$/,
        exclude: /(node_modules)/,
        use: {
          loader: path.resolve(n_path, 'babel-loader'),
          options: {
            presets: [
              [
                path.resolve(n_path, 'babel-preset-env'),
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
              path.resolve(n_path, 'babel-plugin-external-helpers')
            ],
            babelrc: false,
            cacheDirectory: true
          }
        }
      }
    ]
  },
  devtool: 'source-map',
  optimization: {
    // Don't minify even in production mode, we will do it ourselves with UglifyES
    minimize: false
  }
};
