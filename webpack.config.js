const path = require('path');

module.exports = {
  entry: {
    vendor: path.resolve(__dirname, 'src/js/lib/vendor.js')
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }
    ]
  },
  output: {
    path: path.resolve(__dirname, 'preview/js/lib'),
    filename: '[name].min.js',
    library: 'Vendor',
    libraryTarget: 'umd'
  }
};
