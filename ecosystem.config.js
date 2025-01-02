module.exports = {
  apps: [{
    name: 'scraper',
    script: './dist/scraper.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '2G',
    env: {
      NODE_ENV: 'production'
    },
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss'
  }]
}; 