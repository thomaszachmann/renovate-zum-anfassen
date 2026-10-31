// config.js (Drill 7) – globale Config: Org-Standard für jedes Repo.
// globalExtends wird vor der Plattform aufgelöst: kein local>, nur öffentliche URL.
module.exports = {
  globalExtends: [
    'http://127.0.0.1:3000/shop/renovate-config/raw/tag/v1.1.0/default.json',
  ],
};
