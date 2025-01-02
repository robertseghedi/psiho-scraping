module.exports = {
  apps: [{
    name: "scraper",
    script: "./scraper.ts",
    interpreter: "./node_modules/.bin/ts-node",
    watch: false,
    instances: 1,
    exec_mode: "fork",
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: "production"
    }
  }]
} 