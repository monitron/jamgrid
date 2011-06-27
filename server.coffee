
fs = require 'fs'
io = require 'socket.io'
mongoose = require 'mongoose'
express = require 'express'
mongooseAuth = require 'mongoose-auth'
less = require 'less'

config = require './config'

User = require './models/user'
Jam = require './models/jam'
sessions = require './sessions'
realtime = require './realtime'

mongoose.connect 'mongodb://localhost/' + config.mongo_db

app = express.createServer(
  express.bodyParser(),
  express.static(__dirname + "/public"),
  express.cookieParser(),
  express.session({
    secret: config.session_secret,
    cookie: {path: '/', httpOnly: false, maxAge: 360 * 24 * 7},
    store: sessions
  }),
  mongooseAuth.middleware()
)

app.configure ->
  app.set 'view engine', 'jade'

app.get '/', (req, res) ->
  res.render 'welcome'

app.get '/jam/new', (req, res) ->
  unless req.loggedIn
    res.redirect '/'
    return
  jam = new Jam {creator: req.user.id, artists: [req.user.id]}
  jam.save (err) ->
    throw err if err
    res.redirect '/jam/' + jam.id


app.get '/jam/:id', (req, res) ->
  unless req.loggedIn
    res.redirect '/'
    return
  res.render 'jam'

# Render LESS stylesheets from disk
app.get '/css/:sheet.css', (req, res) ->
  fs.readFile 'css/' + req.params.sheet + '.less', 'utf8', (err, data) ->
    throw err if err
    less.render data, (err, css) ->
      throw err if err
      res.contentType "css"
      res.send css

mongooseAuth.helpExpress app

app.listen config.http_port
realtime io.listen(app)