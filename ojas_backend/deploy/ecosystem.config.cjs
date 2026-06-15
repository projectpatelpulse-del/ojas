/**
 * PM2 config — copy to the server next to ojas_backend or set cwd explicitly.
 * Usage (from repo root on VPS):
 *   pm2 start deploy/ecosystem.config.cjs
 *   pm2 save && pm2 startup
 */
const path = require('path');

const backendDir = path.join(__dirname, '..', 'ojas_backend');

module.exports = {
  apps: [
    {
      name: 'ojas-api',
      cwd: backendDir,
      script: 'src/server.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '400M',
      env: {
        NODE_ENV: 'production',
        PORT: 5001,
      },
    },
  ],
};
