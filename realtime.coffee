# The socket.io real-time interface

User = require './models/user'
Jam = require './models/jam'
sessions = require './sessions'

module.exports = (io) ->
  io.sockets.on 'connection', (socket) ->
    socket.emit "welcome"

    jamId = null
    user = null

    # XXX Notice when client disappears

    socket.on 'identify', (sessionId, supposedJamId) ->
      console.log "Client identified as " + sessionId
      sessions.get sessionId, (err, result) ->
        throw err if err
        # XXX fail if err or ! auth or ! auth.loggedIn
        User.findById result.auth.userId, (err, u) ->
          throw err if err
          user = u
          # XXX authorize
          Jam.findById supposedJamId, (err, jam) ->
            throw err if err
            jamId = supposedJamId
            jamdata = jam.toObject()
            jamdata.parts = JSON.parse(jam.music) # Temporary, hopefully :(
            socket.join jamId
            socket.emit 'initjam', jamdata
            socket.broadcast.to(jamId).emit 'join', user
            # TODO Tell this user about all the current users

    socket.on 'writepart', (partId, newData) ->
      if !jamId
        socket.emit 'error', 'writepart without jam'
        return
      console.log "Writing part " + partId
      # XXX Race condition possible here
      Jam.findById jamId, (err, jam) ->
        throw err if err
        parts = JSON.parse(jam.get('music'))
        parts[partId] = newData
        jam.set 'music', JSON.stringify(parts)
        jam.save (err) ->
          throw err if err
          console.log "Part written successfully"
          socket.broadcast.to(jamId).emit 'partchange', partId, newData

    socket.on 'editing', (partId) ->
      socket.broadcast.to(jamId).emit 'editing', user.login, partId