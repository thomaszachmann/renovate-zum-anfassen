// @shop/api – REST-API des Shops (Lab-Demo).
const express = require("express");
const _ = require("lodash");
const app = express();
app.get("/health", (_req, res) => res.json({ ok: true, v: _.VERSION }));
app.listen(8080);
