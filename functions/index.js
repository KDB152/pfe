const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

exports.myFunction = onRequest((request, response) => {
  logger.log("Hello from Firebase!");
  response.send("Hello!");
});
