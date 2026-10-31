// config.js – globale Konfiguration des Lab-Bots (Tag 9)
module.exports = {
  platform: 'forgejo',
  endpoint: 'http://127.0.0.1:3000/api/v1',
  token: process.env.RENOVATE_TOKEN,      // Token nie in die Datei schreiben
  gitAuthor: 'Renovate Bot <renovate-bot@lab.local>',
  autodiscover: true,
  autodiscoverFilter: ['shop/*'],
  onboardingBranch: 'renovate/onboarding',
  onboardingConfig: {
    $schema: 'https://docs.renovatebot.com/renovate-schema.json',
    extends: ['config:recommended', ':timezone(Europe/Berlin)'],
  },
};
