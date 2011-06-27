(function() {
  var Jam, User, app, config, express, fs, io, less, mongoose, mongooseAuth, realtime, sessions;
  fs = require('fs');
  io = require('socket.io');
  mongoose = require('mongoose');
  express = require('express');
  mongooseAuth = require('mongoose-auth');
  less = require('less');
  config = require('./config');
  User = require('./models/user');
  Jam = require('./models/jam');
  sessions = require('./sessions');
  realtime = require('./realtime');
  mongoose.connect('mongodb://localhost/' + config.mongo_db);
  app = express.createServer(express.bodyParser(), express.static(__dirname + "/public"), express.cookieParser(), express.session({
    secret: config.session_secret,
    cookie: {
      path: '/',
      httpOnly: false,
      maxAge: 360 * 24 * 7
    },
    store: sessions
  }), mongooseAuth.middleware());
  app.configure(function() {
    return app.set('view engine', 'jade');
  });
  app.get('/', function(req, res) {
    return res.render('welcome');
  });
  app.get('/jam/new', function(req, res) {
    var jam;
    if (!req.loggedIn) {
      res.redirect('/');
      return;
    }
    jam = new Jam({
      creator: req.user.id,
      artists: [req.user.id]
    });
    return jam.save(function(err) {
      if (err) {
        throw err;
      }
      return res.redirect('/jam/' + jam.id);
    });
  });
  app.get('/jam/:id', function(req, res) {
    if (!req.loggedIn) {
      res.redirect('/');
      return;
    }
    return res.render('jam');
  });
  app.get('/css/:sheet.css', function(req, res) {
    return fs.readFile('css/' + req.params.sheet + '.less', 'utf8', function(err, data) {
      if (err) {
        throw err;
      }
      return less.render(data, function(err, css) {
        if (err) {
          throw err;
        }
        res.contentType("css");
        return res.send(css);
      });
    });
  });
  mongooseAuth.helpExpress(app);
  app.listen(config.http_port);
  realtime(io.listen(app));
}).call(this);
