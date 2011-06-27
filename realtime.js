(function() {
  var Jam, User, sessions;
  User = require('./models/user');
  Jam = require('./models/jam');
  sessions = require('./sessions');
  module.exports = function(io) {
    return io.sockets.on('connection', function(socket) {
      var jamId, user;
      socket.emit("welcome");
      jamId = null;
      user = null;
      socket.on('identify', function(sessionId, supposedJamId) {
        console.log("Client identified as " + sessionId);
        return sessions.get(sessionId, function(err, result) {
          if (err) {
            throw err;
          }
          return User.findById(result.auth.userId, function(err, u) {
            if (err) {
              throw err;
            }
            user = u;
            return Jam.findById(supposedJamId, function(err, jam) {
              var jamdata;
              if (err) {
                throw err;
              }
              jamId = supposedJamId;
              jamdata = jam.toObject();
              jamdata.parts = JSON.parse(jam.music);
              socket.join(jamId);
              socket.emit('initjam', jamdata);
              return socket.broadcast.to(jamId).emit('join', user);
            });
          });
        });
      });
      socket.on('writepart', function(partId, newData) {
        if (!jamId) {
          socket.emit('error', 'writepart without jam');
          return;
        }
        console.log("Writing part " + partId);
        return Jam.findById(jamId, function(err, jam) {
          var parts;
          if (err) {
            throw err;
          }
          parts = JSON.parse(jam.get('music'));
          parts[partId] = newData;
          jam.set('music', JSON.stringify(parts));
          return jam.save(function(err) {
            if (err) {
              throw err;
            }
            console.log("Part written successfully");
            return socket.broadcast.to(jamId).emit('partchange', partId, newData);
          });
        });
      });
      return socket.on('editing', function(partId) {
        return socket.broadcast.to(jamId).emit('editing', user.login, partId);
      });
    });
  };
}).call(this);
