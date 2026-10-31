const express = require("express");
const app = express();
app.get("/health", (_req, res) => res.json({ status: "ok" }));
app.listen(8080, () => console.log("shop-api listening on 8080"));
