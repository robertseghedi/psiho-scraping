module.exports = {
  apps: [{
    name: "scraper",
    script: "./scraper.js",
    watch: false,
    instances: 1,
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: "production"
    }
  }]
} 