(function() {
  var User, app, express, fs, io, less, mongoose, mongooseAuth;
  fs = require('fs');
  io = require('socket.io');
  mongoose = require('mongoose');
  express = require('express');
  mongooseAuth = require('mongoose-auth');
  less = require('less');
  User = require('./models/user');
  mongoose.connect('mongodb://localhost/jamgrid');
  app = express.createServer(express.bodyParser(), express.static(__dirname + "/public"), express.cookieParser(), express.session({
    secret: 'QuiteSomeSecret'
  }), mongooseAuth.middleware());
  app.configure(function() {
    return app.set('view engine', 'jade');
  });
  app.get('/', function(req, res) {
    return res.render('welcome');
  });
  app.get("/instruments/:inst/:sound.:format", function(req, res) {
    return res.sendfile("assets/instruments/" + req.params.inst + "/" + req.params.sound + "." + req.params.format);
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
  app.listen(process.env.PORT || 5000);
}).call(this);
