// Formatiert Cent-Beträge als Euro-String: format(1999) -> "19,99 €"
exports.format = (cents) => (cents / 100).toFixed(2).replace('.', ',') + ' €';
