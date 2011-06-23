
fs = require 'fs'
io = require 'socket.io'
mongoose = require 'mongoose'
express = require 'express'
mongooseAuth = require 'mongoose-auth'
less = require 'less'

User = require './models/user'

mongoose.connect 'mongodb://localhost/jamgrid'

app = express.createServer(
  express.bodyParser(),
  express.static(__dirname + "/public"),
  express.cookieParser(),
  express.session({secret: 'QuiteSomeSecret'}),
  mongooseAuth.middleware()
)

app.configure ->
  app.set 'view engine', 'jade'

app.get '/', (req, res) ->
  res.render 'welcome'

app.get "/instruments/:inst/:sound.:format", (req, res) ->
  res.sendfile "assets/instruments/" + req.params.inst + "/" +
    req.params.sound + "." + req.params.format

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

app.listen process.env.PORT || 5000
