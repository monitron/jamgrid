# Prototype to test the viability of sequencing multiple simultaneous HTML5
# audio plays to create something like music!

bpm = 300
position = -1
lastBeat = 0

music = [
  ['bass', 'closedhat'],
  [],
  [],
  ['bass'],
  ['bass'],
  ['closedhat'],
  ['bass'],
  [],
  ['bass', 'closedhat'],
  [],
  [],
  ['bass'],
  ['bass'],
  ['closedhat'],
  ['bass'],
  []
  ]

# Scales are defined by an array of pitch classes
scales =
  "Major Pentatonic": [0, 2, 4, 7, 9],

class Instrument
  constructor: (@key, @name) ->

  fileName: (@soundKey, @format) ->
    "instruments/" + @key + "/" + @soundKey + "." + @format

class PitchedInstrument extends Instrument
  constructor: (@key, @name, @notes) ->

  notesForScale: (scale) ->
    note for note in @notes when note % 12 in scale

instruments = [
  new PitchedInstrument "epiano", "E-Piano", [36..69]
]

lastBeat = 15

class InstrumentGrid extends Backbone.View
  className: "instrumentGrid"

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

beat = ->
  position += 1
  position = 0 if position > 15
  console.log "beat! pos = " + position
  for sample in music[position]
    element = $("#" + sample)[0]
    needsPlaying = element.currentTime == 0
    element.currentTime = 0
    element.play() if needsPlaying

tick = ->
  time = (new Date).getTime()
  if time - lastBeat >= (1000 / (bpm / 60)) - 3
    lastBeat = time
    beat()

window.play = ->
  setInterval tick, 1

$ ->
  console.log "here goes"
  theInstrument = instruments[0]
  theScale = scales["Major Pentatonic"]
  theGrid = new InstrumentGrid {instrument: theInstrument, scale: theScale}
  theGrid.render()
  $(document.body).append(theGrid.el);

