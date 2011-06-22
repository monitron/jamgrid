
io = require 'socket.io'
mongoose = require 'mongoose'
express = require 'express'
mongooseAuth = require 'mongoose-auth'
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

mongooseAuth.helpExpress app

app.listen process.env.PORT || 5000
