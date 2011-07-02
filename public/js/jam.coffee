# Scales are defined by an array of pitch classes
window.scales =
  "Major Pentatonic": [0, 2, 4, 7, 9]
  "Minor Pentatonic": [0, 3, 5, 7, 10]
  "Chromatic": [0..11]

class Instrument
  constructor: (@key, @name) ->

  filename: (@soundKey, @format) ->
    "/instruments/" + @key + "/" + @soundKey + "." + @format

class PitchedInstrument extends Instrument
  constructor: (@key, @name, @notes) ->

  soundsForScale: (scale) ->
    note for note in @notes when note % 12 in scale

class PercussionInstrument extends Instrument
  constructor: (@key, @name, @sounds) ->

  iconFilename: (@soundKey) ->
    "/instruments/" + @key + "/" + @soundKey + ".png"

  soundsForScale: (scale) ->
    @sounds

window.instruments =
  epiano: new PitchedInstrument("epiano", "E-Piano", [28..63])
  808: new PercussionInstrument("808", "808",
    ['bass', 'closedhat', 'openhat', 'snare', 'cymbal', 'clap', 'cowbell'])

class Jam extends Backbone.Model
  setPart: (instrumentKey, part, fromServer = false) ->
    parts = _.clone(this.get("parts"))
    parts[instrumentKey] = part
    this.set {parts: parts}
    this.trigger("userchangedpart", instrumentKey, part) unless fromServer

  getPart: (instrumentKey) ->
    this.get("parts")[instrumentKey] || []


class ModalView extends Backbone.View
  initialize: ->
    this.render()

  render: ->
    @curtainEl = $('<div />').addClass('modalCurtain')
    @el = $('<div />').addClass('modalContainer')
    this.renderContent()
    $(document.body).append @el
    $(document.body).append @curtainEl

  remove: ->
    super
    @curtainEl.remove()


class ErrorView extends ModalView
  initialize: (error) ->
    @error = error
    super
    @el.addClass 'error'

  renderContent: ->
    @el.append $('<h2 />').html('Bad News :(')
    @el.append $('<p />').html(@error)


class LoadingView extends ModalView
  initialize: ->
    super
    this.say "Reticulating splines"
    window.client.bind 'connecting', => this.say "Connecting to server"
    window.client.bind 'connected', => this.say "Joining jam"
    window.client.bind 'jamloaded', => this.say "Loading samples"
    window.player.bind 'sampleloaded', =>
      this.say "Loading samples (" + window.player.numSamplesLoading() + " remain)"
    window.player.bind 'ready', => this.remove()

  say: (message) ->
    this.$('P').html message

  renderContent: ->
    @el.append($('<h2 />').html('Prepare to Jam'))
    @messageEl = @el.append('<p />')


class JamView extends Backbone.View
  initialize: ->
    _.defer => # Give others a chance to bind events first
      this.render()
      window.player.bind 'playing', =>
        this.$('.playButton').hide()
        this.$('.stopButton').show()
      window.player.bind 'stopping', =>
        this.$('.playButton').show()
        this.$('.stopButton').hide()
      this.editPart "epiano"
      @chatView = new ChatView {el: this.$('.chat')}

  events:
    "click .playButton":     "play"
    "click .stopButton":     "stop"
    "click .instruments li": "editPart"

  editPart: (instrumentKey) ->
    instrumentKey = $(instrumentKey.target).data('key') if instrumentKey.target?
    this.trigger 'editing', instrumentKey
    # XXX Remove old part if any (huge leak)
    @editingInstrument = instrumentKey
    @partView = new PartView {jam: @model, instrumentKey: instrumentKey, el: this.$('.part')}
    # Update appearance of instrument tabs
    this.$('.instruments li').removeClass('current')
    this.$('.instruments li[data-key=' + instrumentKey + ']').addClass('current')

  play: -> window.player.play()

  stop: -> window.player.stop()

  render: ->
    instruments = $('<ul />').addClass('instruments')
    for key, instrument of window.instruments
      instruments.append $('<li />').html(instrument.name).attr('data-key', instrument.key)
    editor = $('<div />').addClass('editor').html(instruments)
    editor.append $('<div />').addClass('part')
    bar = $('<div />').addClass('controls')
    bar.append $('<button />').html('Play').addClass('playButton')
    bar.append $('<button />').html('Stop').addClass('stopButton').hide()
    $(@el).html(bar).append(editor).append($('<div />').addClass('chat'))


class ChatView extends Backbone.View
  initialize: ->
    this.render()

  render: ->
    $(@el).html($('<div />').addClass('received'))


class PartView extends Backbone.View
  initialize: ->
    @jam = @options.jam
    @instrument = window.instruments[@options.instrumentKey]
    @scale = window.scales[@jam.get("scale")]
    @beats = [0..@jam.get('patternLength') - 1]
    @sounds = @instrument.soundsForScale(@scale)
    this.render()
    window.player.bind 'beat', (num) => this.setCurrentBeat(num)
    window.player.bind 'stopping', => this.setCurrentBeat(null)
    @jam.bind 'change:parts', => this.populateFromJam()
    this.populateFromJam()

  events:
    "click TD.toggleable": "toggleCell"
    "click .clearButton": "resetPattern"

  render: ->
    table = $('<table />')
    for sound in @sounds
      row = $('<tr />')
      if @instrument.iconFilename?
        label = $('<img />').attr('src', @instrument.iconFilename(sound))
      else
        label = ''
      row.append($('<td />').html(label).addClass('label'))
      for beat in @beats
        row.append($('<td />').attr('data-beat', beat).attr('data-sound', sound).addClass('toggleable'))
      table.prepend(row)
    container = $('<div />')
    container.append $('<h3 />').html('Edit ' + @instrument.name)
    container.append table
    container.append $('<button />').html('Clear').addClass('clearButton')
    $(@el).html(container)

  populateFromJam: ->
    this.setCells @jam.getPart(@options.instrumentKey)

  toggleCell: (event) ->
    $(event.target).toggleClass('on')
    this.updateModel()

  resetPattern: ->
    this.clearCells()
    this.updateModel()

  findCell: (beat, sound) ->
    this.$("td[data-beat=" + beat + "][data-sound=" + sound + "]")

  clearCells: ->
    this.$("td").removeClass('on')

  setCells: (part) ->
    this.clearCells()
    for sounds, beatNum in part
      for sound in sounds
        this.findCell(beatNum, sound).addClass('on')

  setCurrentBeat: (beat) ->
    this.$("td").removeClass('current')
    this.$("td[data-beat=" + beat + "]").addClass('current') if beat?

  # Serialize the pattern and set it in our jam
  updateModel: ->
    part = ([] for n in [1..@jam.get('patternLength')])
    for cell in this.$("td.on")
      cell = $(cell)
      part[cell.data('beat')].push(cell.data('sound'))
    @jam.setPart(@options.instrumentKey, part)


class Client
  constructor: ->
    _.extend this, Backbone.Events # there's probably a better way to do this!
    @jamid = _.last(document.location.pathname.split("/"))
    @sessionid = $.cookie('connect.sid')
    console.log "Trying to connect"
    this.trigger 'connecting'
    @socket = io.connect()
    @socket.on 'welcome', =>
      this.trigger 'connected'
      console.log "We were welcomed"
      @socket.emit 'identify', @sessionid, @jamid

    @socket.on 'initjam', (jamdata) =>
      return if @jam? # Don't reload on reconnect
      this.trigger 'jamloaded'
      @jam = new Jam(jamdata)
      window.player.loadJam(@jam)
      view = new JamView {model: @jam, el: $('#jam')[0]}
      @jam.bind 'userchangedpart', (instKey, data) =>
        @socket.emit 'writepart', instKey, data
      view.bind 'editing', (instKey) =>
        @socket.emit 'editing', instKey

    @socket.on 'partchange', (instKey, data) =>
      @jam.setPart instKey, data, true

    @socket.on 'editing', (login, instKey) =>
      console.log login + " is now editing " + instKey

class Player
  format: "wav"
  tickInterval: 5    # Milliseconds between beat checks (ticks)

  constructor: ->
    _.extend this, Backbone.Events # there's probably a better way to do this!
    @state = "unprepared"
    console.log "Player feels woefully unprepared"

  loadJam: (jam) ->
    @beatInterval = 1000 / (jam.get('speed') / 60)
    @patternLength = jam.get('patternLength')
    @scale = window.scales[jam.get('scale')]
    @parts = jam.get('parts')
    jam.bind "change:parts", => @parts = jam.get("parts")
    console.log "Player loaded jam"
    this.prepare()

  beginPattern: ->
    console.log "Player beginning pattern"
    @patternPos = 0

  tick: ->
    time = (new Date).getTime()
    if time - @lastBeat >= @beatInterval
      @lastBeat = time
      this.beat()

  beat: ->
    console.log "Player: beat! pos = " + @patternPos
    this.beginPattern() if @patternPos == @patternLength
    for instrumentKey, part of @parts
      instrument = window.instruments[instrumentKey]
      this.playSound instrument, sound for sound in part[@patternPos]
    this.trigger 'beat', @patternPos
    @patternPos += 1

  play: ->
    if @state != "ready"
      console.log "Player isn't ready to play"
      return
    @state = "playing"
    this.trigger "playing"
    console.log "Player playing"
    this.beginPattern()
    @lastBeat = 0
    @tickIntervalID = setInterval =>
      this.tick()
    , @tickInterval

  stop: ->
    if @state != "playing"
      console.log "Player can't stop - it isn't playing"
      return
    @state = "ready"
    this.trigger 'stopping'
    clearInterval @tickIntervalID


class HTML5Player extends Player
  samplePolyphony: 2 # Number of <audio> elements per sample

  constructor: ->
    super
    @samples = {}

  # Load all relevant sounds
  prepare: ->
    for key, instrument of window.instruments
      for sound in instrument.soundsForScale(@scale)
        filename = instrument.filename(sound, @format)
        @samples[filename] = for num in [1..@samplePolyphony]
          audioEl = $('<audio />').attr('src', filename).data({state: 'loading', n: num})
          audioEl.bind 'canplaythrough', (ev) =>
            sample = $(ev.target)
            sample.data('state', 'ready').unbind()
            this.trigger 'sampleloaded'
            console.log "Player loaded " + ev.target.src + "!"
            # Sample should take note of when it is done playing
            sample.bind 'ended', (ev) -> $(ev.target).data 'state', 'ready'
            # Are we done preparing yet?
            if this.numSamplesLoading() == 0
              @state = 'ready'
              this.trigger 'ready'
              console.log "Player ready"
          console.log "Player loading " + filename
          audioEl[0]
    @state = "preparing"

  numSamplesLoading: ->
    (1 for el in _.flatten(@samples) when $(el).data('state') == 'loading').length

  readyElementForSample: (filename) ->
    for el in @samples[filename]
      return el if $(el).data('state') == 'ready'
    console.log "Player sample elements exhausted for " + filename
    # TODO Pick one to restart?
    return null

  playSound: (instrument, sound) ->
    if sample = this.readyElementForSample(instrument.filename(sound, @format))
      $(sample).data 'state', 'playing'
      needsPlaying = sample.currentTime == 0
      sample.currentTime = 0
      sample.play() if needsPlaying


# A player using the popular SoundManager2 flash hack :)
class SoundManagerPlayer extends Player
  format: "mp3"

  constructor: ->
    super
    @sm = window.soundManager
    @samplesLoading = 0

  prepare: (callback) ->
    @state = "preparing"

    @sm.ontimeout ->
      @state = "broken"
      new ErrorView "Your platform requires Flash to play audio reliably, but Flash failed to load. Please disable any Flash blocker and reload the page."

    @sm.onready =>
      console.log "sm is ready"
      for key, instrument of window.instruments
        for sound in instrument.soundsForScale(@scale)
          filename = instrument.filename(sound, @format)
          @samplesLoading += 1
          @sm.createSound {
            id: filename,
            url: filename,
            autoLoad: true,
            autoPlay: false,
            volume: 50,
            onload: =>
              @samplesLoading -= 1
              console.log "SM loaded " + filename + "!"
              this.trigger 'sampleloaded'
              if @samplesLoading == 0
                @state = 'ready'
                this.trigger 'ready'
                console.log "Player ready"
          }

  numSamplesLoading: ->
    return @samplesLoading

  playSound: (instrument, sound) ->
    @sm.play instrument.filename(sound, @format)


# XXX Move these somewhere more reasonable
window.soundManager.url = '/swf/' if window.soundManager?
window.soundManager.flashVersion = 9;
window.soundManager.useHighPerformance = true;
window.soundManager.useConsole = false;
window.soundManager.debugMode = false;

$ ->
  window.console = { log: -> } if !window.console?
  console.log "Initializing"
  window.player = new SoundManagerPlayer
  window.client = new Client
  new LoadingView
