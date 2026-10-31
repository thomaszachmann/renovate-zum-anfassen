// challenge.config.js – Org-Bot nur für shop (Tag 9, Challenge)
module.exports = {
  platform: 'forgejo',
  endpoint: 'http://127.0.0.1:3000/api/v1',
  token: process.env.RENOVATE_TOKEN,
  gitAuthor: 'Renovate Bot <renovate-bot@lab.local>',
  autodiscover: true,
  autodiscoverFilter: ['*/*', '!lager/*'],
  requireConfig: 'required',
  onboardingBranch: 'renovate/onboarding',
  onboardingConfig: {
    $schema: 'https://docs.renovatebot.com/renovate-schema.json',
    extends: [
      'config:recommended',
      ':timezone(Europe/Berlin)',
      'schedule:earlyMondays',
    ],
  },
  repositoryCache: 'enabled',
  exitCodeForErrors: true,
};
