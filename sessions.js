(function() {
  var MongoStore, config;
  MongoStore = require('connect-mongo');
  config = require('./config');
  module.exports = new MongoStore({
    db: config.mongo_db
  });
}).call(this);
