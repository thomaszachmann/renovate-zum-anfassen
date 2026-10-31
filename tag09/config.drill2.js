// config.js – globale Konfiguration des Lab-Bots (Tag 9)
module.exports = {
  platform: 'forgejo',
  endpoint: 'http://127.0.0.1:3000/api/v1',
  token: process.env.RENOVATE_TOKEN,      // Token nie in die Datei schreiben
  gitAuthor: 'Renovate Bot <renovate-bot@lab.local>',
  repositories: ['shop/shop-worker'],
};
