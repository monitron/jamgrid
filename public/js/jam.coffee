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
    "/images/instruments/" + @key + "/sounds/" + @soundKey + ".png"

  soundsForScale: (scale) ->
    @sounds

window.instruments =
  epiano: new PitchedInstrument("epiano", "E-Piano", [28..63])
  808: new PercussionInstrument("808", "808",
    ['bass', 'closedhat', 'openhat', 'snare', 'cymbal', 'clap', 'cowbell'])

class Jam extends Backbone.Model
  defaults:
    parts: {}
    scale: "Minor Pentatonic"
    patternLength: 16 # beats
    speed: 280 # beats per minute

  setPart: (instrumentKey, part) ->
    parts = _.clone(this.get("parts"))
    parts[instrumentKey] = part
    this.set({parts: parts})

  getPart: (instrumentKey) ->
    this.get("parts")[instrumentKey] || []


class JamView extends Backbone.View
  initialize: ->
    this.render()
    this.editPart "epiano"

  events:
    "click .playButton":     "play"
    "click .stopButton":     "stop"
    "click .instruments li": "editPart"

  editPart: (instrumentKey) ->
    instrumentKey = $(instrumentKey.target).data('key') if instrumentKey.target?
    # XXX Remove old part if any
    @editingInstrument = instrumentKey
    @partView = new PartView {jam: @model, instrumentKey: instrumentKey, el: this.$('.part')}

  play: -> window.player.play()

  stop: -> window.player.stop()

  render: ->
    instruments = $('<ul />').addClass('instruments')
    for key, instrument of window.instruments
      instruments.append $('<li />').html(instrument.name).data('key', instrument.key)
    buttons = $('<div />')
    buttons.append $('<button />').html('Play').addClass('playButton')
    buttons.append $('<button />').html('Stop').addClass('stopButton')
    $(@el).html instruments
    $(@el).append $('<div />').addClass('part')
    $(@el).append buttons


class PartView extends Backbone.View
  initialize: ->
    @jam = @options.jam
    @instrument = window.instruments[@options.instrumentKey]
    @scale = window.scales[@jam.get("scale")]
    @beats = [0..@jam.get('patternLength') - 1]
    @sounds = @instrument.soundsForScale(@scale)
    this.render()
    this.setCells @jam.getPart(@options.instrumentKey)
    window.player.bind 'beat', (num) => this.setCurrentBeat(num)

  events:
    "click TD.toggleable": "toggleCell"
    "click .clearButton": "resetPattern"

  render: ->
    table = $('<table />')
    for sound in @sounds
      row = $('<tr />')
      row.append($('<td />').html(sound).addClass('label'))
      for beat in @beats
        row.append($('<td />').attr('data-beat', beat).attr('data-sound', sound).addClass('toggleable'))
      table.prepend(row)
    container = $('<div />')
    container.append $('<h3 />').html('Edit ' + @instrument.name)
    container.append table
    container.append $('<button />').html('Clear').addClass('clearButton')
    $(@el).html(container)

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
    this.$("td[data-beat=" + beat + "]").addClass('current')

  # Serialize the pattern and set it in our jam
  updateModel: ->
    part = ([] for n in [1..@jam.get('patternLength')])
    for cell in this.$("td.on")
      cell = $(cell)
      part[cell.data('beat')].push(cell.data('sound'))
    @jam.setPart(@options.instrumentKey, part)


class Player
  format: "wav"
  tickInterval: 5    # Milliseconds between beat checks (ticks)
  samplePolyphony: 2 # Number of <audio> elements per sample

  constructor: ->
    _.extend this, Backbone.Events # there's probably a better way to do this!
    @samples = {}
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

  # Load all relevant sounds
  prepare: (callback) ->
    for key, instrument of window.instruments
      for sound in instrument.soundsForScale(@scale)
        filename = instrument.filename(sound, @format)
        @samples[filename] = for num in [1..@samplePolyphony]
          audioEl = $('<audio />').attr('src', filename).data({state: 'loading', n: num})
          audioEl.bind 'canplaythrough', (ev) =>
            sample = $(ev.target)
            sample.data('state', 'ready').unbind()
            console.log "Player loaded " + ev.target.src + "!"
            # Sample should take note of when it is done playing
            sample.bind 'ended', (ev) -> $(ev.target).data 'state', 'ready'
            # Are we done preparing yet?
            if this.numSamplesLoading() == 0
              @state = 'ready'
              console.log "Player ready"
              callback() if callback?
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
      for sound in part[@patternPos]
        if sample = this.readyElementForSample(instrument.filename(sound, @format))
          $(sample).data 'state', 'playing'
          needsPlaying = sample.currentTime == 0
          sample.currentTime = 0
          sample.play() if needsPlaying
    this.trigger 'beat', @patternPos
    @patternPos += 1

  play: ->
    if @state != "ready"
      console.log "Player isn't ready to play"
      return
    @state = "playing"
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
    clearInterval @tickIntervalID


$ ->
  window.console = { log: -> } if !window.console?
  console.log "Initializing"
  window.player = new Player
  window.jam = new Jam
  window.player.loadJam(window.jam)
  new JamView {model: window.jam, el: $('#jam')[0]}
