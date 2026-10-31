// config.js – globale Konfiguration des billing-Bots (Anhang B, Aufgabe 2)
module.exports = {
  platform: 'forgejo',
  endpoint: 'http://127.0.0.1:3000/api/v1',
  token: process.env.RENOVATE_TOKEN,      // Token nie in die Datei schreiben
  gitAuthor: 'Renovate Bot <renovate-bot@lab.local>',
  autodiscover: true,
  autodiscoverFilter: ['billing/*'],
  onboardingConfig: {
    $schema: 'https://docs.renovatebot.com/renovate-schema.json',
    extends: ['local>billing/renovate-config'],
  },
};
