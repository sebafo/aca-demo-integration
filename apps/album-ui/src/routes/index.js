var express = require("express");
var router = express.Router();
require("dotenv").config();
const axios = require("axios");
const background = process.env.BACKGROUND_COLOR;
process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;

var baseURL = process.env.API_BASE_URL || "https://localhost:3501";

const api = axios.create({
  baseURL: baseURL,
  params: {},
  timeout: process.env.TIMEOUT || 15000,
});

/* GET home page. */
router.get("/", async function (req, res, next) {
  try {
    console.log("Sending request to backend albums api");
    var data = await api.get("/albums");
    console.log("Response from backend albums api: ", data.data);
    res.render("index", {
      albums: data.data,
      background_color: background,
      baseURL: baseURL
    });
  } catch (err) {
    console.log("Error: ", err);
    next(err);
  }
});

/* Put request to stream album */
router.put("/stream/:id", async function (req, res, next) {
  try {
    console.log("Sending request to backend albums api");
    await api.put("/albums/" + req.params.id);
    res.status(202).send();
  } catch (err) {
    console.log("Error: ", err);
    next(err);
  }
});

module.exports = router;
