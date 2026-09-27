const CompressionWebpackPlugin = require('compression-webpack-plugin')

module.exports = {
  // 设置打包输出目录
  assetsDir: 'assets',
  outputDir: '../public/adminadmin',  // ← 这里指定输出目录，比如 dist/custom-output
  publicPath: process.env.NODE_ENV === 'production'
    ? '/adminadmin/' // 👉 生产环境静态资源路径（以 / 开头，结尾也建议加 /）
    : '/',
  productionSourceMap: false,
  transpileDependencies: ['element-ui', 'ele-admin', 'vue-i18n'],

  // 开发服务器配置
  devServer: {
    port: 8080,
    proxy: {
      // 代理/admin路径到后端API
      '/admin': {
        target: process.env.VUE_APP_API_PROXY || 'http://127.0.0.1:8000',
        changeOrigin: true,
        secure: false,
        ws: true,
        logLevel: 'debug',
        // 添加错误处理
        onError: function(err, _req, _res) {
          console.error('Proxy error:', err)
        }
      },
      // 代理/api路径
      '/api': {
        target: process.env.VUE_APP_API_PROXY || 'http://127.0.0.1:8000',
        changeOrigin: true,
        secure: false,
        ws: true
      }
    }
  },

  chainWebpack: (config) => {
    config.plugins.delete('prefetch')
    if (process.env.NODE_ENV !== 'development') {
      // 对超过10kb的文件进行 gzip 压缩
      config.plugin('compressionPlugin').use(new CompressionWebpackPlugin({
        test: /\.(js|css|html)$/,
        threshold: 10240
      }))
    }if (process.env.NODE_ENV === 'production') {
      config.plugin('compressionPlugin').use(
        new CompressionWebpackPlugin({
          test: /\.(js|css|less)$/,
          threshold: 10240, // 对超过10kb的文件压缩
          deleteOriginalAssets: false
        })
      )
    }
  },
  css: {
    loaderOptions: {
      sass: {
        sassOptions: {
          outputStyle: 'expanded'
        }
      }
    }
  }
}
