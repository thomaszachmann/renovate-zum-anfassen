// config.js – globale Renovate-Config für den CronJob (landet als ConfigMap im Pod)
module.exports = {
  platform: 'forgejo',
  endpoint: 'http://forgejo:3000/api/v1', // Containername im Docker-Netz "kind"
  gitUrl: 'endpoint', // klonen über den Endpoint-Host statt über clone_url
  gitAuthor: 'Renovate Bot <renovate-bot@lab.local>',
  autodiscover: true,
  autodiscoverFilter: ['shop/*'],
  repositoryCache: 'enabled',
  // Token kommt als RENOVATE_TOKEN aus dem Secret, nie aus dieser Datei
};
