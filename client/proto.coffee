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
      epiano: [
        [36, 40],
        [38, 43],
        [40, 45],
        [43, 48],
        [45, 50],
        [48, 52],
        [50, 55],
        [52, 57],
        [55, 60],
        [57, 62],
        [60, 64],
        [62, 67],
        [64, 69],
        [67, 36],
        [69, 67],
        [69, 36]
        ]

  setPart: (instrumentKey, part) ->
    parts = this.get("parts")
    parts[instrumentKey] = part
    this.set("parts", parts)

  getPart: (instrumentKey) ->
    this.get("parts")[instrumentKey] || []


class JamView extends Backbone.View
  render: ->
    $(@el).html("ahem...")


class PartView extends Backbone.View
  className: "part"

  events:
    "click TD": "toggleCell"

  render: ->
    table = $('<table />')
    for beat in [0..lastBeat]
      row = $('<tr />')
      for note in @options.instrument.notesForScale(@options.scale)
        row.append($('<td />').data({beat: beat, note: note}))
      table.append(row)
    $(@el).html(table)

  toggleCell: (event) ->
    $(event.target).toggleClass('on')


class Player
  format: "wav"
  tickInterval: 5 # Milliseconds between beat checks (ticks)

  constructor: ->
    @samples = {}
    @state = "unprepared"
    console.log "Player feels woefully unprepared"

  loadJam: (jam) ->
    @beatInterval = 1000 / (jam.get('speed') / 60)
    @patternLength = jam.get('patternLength')
    @scale = window.scales[jam.get('scale')]
    this.stageParts jam.get('parts')
    console.log "Player loaded jam"
    this.prepare()

  # Load all known sounds
  prepare: (callback) ->
    @prepareCallback = callback
    for key, instrument of window.instruments
      for note in instrument.notesForScale(@scale)
        filename = instrument.filename(note, @format)
        audioEl = $('<audio />').attr('src', filename).data({state: 'loading'})
        audioEl.bind 'canplaythrough', (ev) =>
          $(ev.target).data {state: 'ready'}
          $(ev.target).unbind()
          console.log "Player loaded " + ev.target.src + "!"
          # Are we done yet?
          if this.numSamplesLoading() == 0
            @state = 'ready'
            console.log "Player ready"
            @prepareCallback() if @prepareCallback?
        @samples[filename] = audioEl[0]
        console.log "Player loading " + filename
    @state = "preparing"

  numSamplesLoading: ->
    (1 for fn, sample of @samples when $(sample).data('state') == 'loading').length

  stageParts: (parts) ->
    @stagedParts = parts
    console.log "Player staged new parts"

  beginPattern: ->
    console.log "Player beginning pattern"
    @patternPos = 0
    if @stagedParts?
      console.log "Player moved staged parts to main"
      @parts = @stagedParts
      @stagedParts = null

  tick: ->
    time = (new Date).getTime()
    if time - @lastBeat >= @beatInterval
      @lastBeat = time
      this.beat()

  beat: ->
    console.log "Player: beat! pos = " + @patternPos
    @patternPos += 1
    this.beginPattern() if @patternPos == @patternLength
    for instrumentKey, part of @parts
      instrument = window.instruments[instrumentKey]
      for note in part[@patternPos]
        sample = @samples[instrument.filename(note, @format)]
        needsPlaying = sample.currentTime == 0
        sample.currentTime = 0
        sample.play() if needsPlaying

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
  #jamView = new JamView {el: $('#all')[0]}
  #jamView.render()
