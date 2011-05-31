# Prototype to test the viability of sequencing multiple simultaneous HTML5
# audio plays to create something like music!

# Scales are defined by an array of pitch classes
window.scales =
  "Major Pentatonic": [0, 2, 4, 7, 9]

class Instrument
  constructor: (@key, @name) ->

  filename: (@soundKey, @format) ->
    "instruments/" + @key + "/" + @soundKey + "." + @format

class PitchedInstrument extends Instrument
  constructor: (@key, @name, @notes) ->

  notesForScale: (scale) ->
    note for note in @notes when note % 12 in scale

window.instruments =
  epiano: new PitchedInstrument("epiano", "E-Piano", [36..69])

class Jam extends Backbone.Model
  defaults:
    parts: {}
    scale: "Major Pentatonic"
    patternLength: 16 # beats
    speed: 280 # beats per minute
    parts:
      epiano: [[36,45,50,69],[36,45,50],[64],[],[36,48,52,67],[36,48,52],[62],[36],[36,43,48,64],[36,43,48],[60],[],[36,50,55,62],[36,50,55],[57],[36]]

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
    "click .playButton": "play"
    "click .stopButton": "stop"

  editPart: (instrumentKey) ->
    # XXX Remove old part if any
    @editingInstrument = instrumentKey
    @partView = new PartView {jam: @model, instrumentKey: instrumentKey, el: this.$('.part')}

  play: -> window.player.play()

  stop: -> window.player.stop()

  render: ->
    part = $('<div />').addClass('part')
    buttons = $('<div />')
    buttons.append $('<button />').html('Play').addClass('playButton')
    buttons.append $('<button />').html('Stop').addClass('stopButton')
    $(@el).html part
    $(@el).append buttons


class PartView extends Backbone.View
  initialize: ->
    @jam = @options.jam
    @instrument = window.instruments[@options.instrumentKey]
    @scale = window.scales[@jam.get("scale")]
    @beats = [0..@jam.get('patternLength') - 1]
    @notes = @instrument.notesForScale(@scale)
    this.render()
    this.setCells @jam.getPart(@options.instrumentKey)
    window.player.bind 'beat', (num) => this.setCurrentBeat(num)

  events:
    "click TD": "toggleCell"
    "click .clearButton": "resetPattern"

  render: ->
    table = $('<table />')
    for note in @notes
      row = $('<tr />')
      for beat in @beats
        row.append($('<td />').attr('data-beat', beat).attr('data-note', note))
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

  findCell: (beat, note) ->
    this.$("td[data-beat=" + beat + "][data-note=" + note + "]")

  clearCells: ->
    this.$("td").removeClass('on')

  setCells: (part) ->
    this.clearCells()
    for notes, beatNum in part
      for note in notes
        this.findCell(beatNum, note).addClass('on')

  setCurrentBeat: (beat) ->
    this.$("td").removeClass('current')
    this.$("td[data-beat=" + beat + "]").addClass('current')

  # Serialize the pattern and set it in our jam
  updateModel: ->
    part = for beat in @beats
      note for note in @notes when this.findCell(beat, note).hasClass('on')
    @jam.setPart(@options.instrumentKey, part)


class Player
  format: "wav"
  tickInterval: 5    # Milliseconds between beat checks (ticks)
  samplePolyphony: 2 # Number of <audio> elements per sample

  constructor: ->
    _.extend this, Backbone.Events # there's robably a better way to do this!
    @samples = {}
    @state = "unprepared"
    console.log "Player feels woefully unprepared"

  loadJam: (jam) ->
    @beatInterval = 1000 / (jam.get('speed') / 60)
    @patternLength = jam.get('patternLength')
    @scale = window.scales[jam.get('scale')]
    this.stageParts jam.get('parts')
    jam.bind "change:parts", =>
      this.stageParts jam.get("parts")
    console.log "Player loaded jam"
    this.prepare()

  # Load all relevant sounds
  prepare: (callback) ->
    for key, instrument of window.instruments
      for note in instrument.notesForScale(@scale)
        filename = instrument.filename(note, @format)
        @samples[filename] = for num in [1..@samplePolyphony]
          audioEl = $('<audio />').attr('src', filename).data('state', 'loading')
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

  stageParts: (parts) ->
    @stagedParts = parts
    console.log "Player staged new parts"

  beginPattern: ->
    console.log "Player beginning pattern"
    @patternPos = 0
    if @stagedParts?
      console.log "Player moved staged parts to main"
      @parts = _.clone(@stagedParts)
      @stagedParts = null

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
      for note in part[@patternPos]
        if sample = this.readyElementForSample(instrument.filename(note, @format))
          $(sample).data 'state', 'playing'
          needsPlaying = sample.currentTime == 0
          sample.currentTime = 0
          sample.play() if needsPlaying
    this.trigger 'beat', @patternPos
    @patternPos += 1

  play: ->
    if @state != "ready"
      console.log "Player can't play in this state"
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
  console.log "here goes"
  window.player = new Player
  window.jam = new Jam
  window.player.loadJam(window.jam)
  jamView = new JamView {model: window.jam, el: $('#all')[0]}
