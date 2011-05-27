(function() {
  var Instrument, InstrumentGrid, PitchedInstrument, beat, bpm, instruments, lastBeat, music, position, scales, tick, _i, _results;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  bpm = 300;
  position = -1;
  lastBeat = 0;
  music = [['bass', 'closedhat'], [], [], ['bass'], ['bass'], ['closedhat'], ['bass'], [], ['bass', 'closedhat'], [], [], ['bass'], ['bass'], ['closedhat'], ['bass'], []];
  scales = {
    "Major Pentatonic": [0, 2, 4, 7, 9]
  };
  Instrument = (function() {
    function Instrument(key, name) {
      this.key = key;
      this.name = name;
    }
    Instrument.prototype.fileName = function(soundKey, format) {
      this.soundKey = soundKey;
      this.format = format;
      return "instruments/" + this.key + "/" + this.soundKey + "." + this.format;
    };
    return Instrument;
  })();
  PitchedInstrument = (function() {
    __extends(PitchedInstrument, Instrument);
    function PitchedInstrument(key, name, notes) {
      this.key = key;
      this.name = name;
      this.notes = notes;
    }
    PitchedInstrument.prototype.notesForScale = function(scale) {
      var note, _i, _len, _ref, _ref2, _results;
      _ref = this.notes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        note = _ref[_i];
        if (_ref2 = note % 12, __indexOf.call(scale, _ref2) >= 0) {
          _results.push(note);
        }
      }
      return _results;
    };
    return PitchedInstrument;
  })();
  instruments = [
    new PitchedInstrument("epiano", "E-Piano", (function() {
      _results = [];
      for (_i = 36; _i <= 69; _i++){ _results.push(_i); }
      return _results;
    }).apply(this, arguments))
  ];
  lastBeat = 15;
  InstrumentGrid = (function() {
    __extends(InstrumentGrid, Backbone.View);
    function InstrumentGrid() {
      InstrumentGrid.__super__.constructor.apply(this, arguments);
    }
    InstrumentGrid.prototype.className = "instrumentGrid";
    InstrumentGrid.prototype.events = {
      "click TD": "toggleCell"
    };
    InstrumentGrid.prototype.render = function() {
      var beat, note, row, table, _j, _len, _ref;
      table = $('<table />');
      for (beat = 0; 0 <= lastBeat ? beat <= lastBeat : beat >= lastBeat; 0 <= lastBeat ? beat++ : beat--) {
        row = $('<tr />');
        _ref = this.options.instrument.notesForScale(this.options.scale);
        for (_j = 0, _len = _ref.length; _j < _len; _j++) {
          note = _ref[_j];
          row.append($('<td />').data({
            beat: beat,
            note: note
          }));
        }
        table.append(row);
      }
      return $(this.el).html(table);
    };
    InstrumentGrid.prototype.toggleCell = function(event) {
      return $(event.target).toggleClass('on');
    };
    return InstrumentGrid;
  })();
  beat = function() {
    var element, needsPlaying, sample, _j, _len, _ref, _results2;
    position += 1;
    if (position > 15) {
      position = 0;
    }
    console.log("beat! pos = " + position);
    _ref = music[position];
    _results2 = [];
    for (_j = 0, _len = _ref.length; _j < _len; _j++) {
      sample = _ref[_j];
      element = $("#" + sample)[0];
      needsPlaying = element.currentTime === 0;
      element.currentTime = 0;
      _results2.push(needsPlaying ? element.play() : void 0);
    }
    return _results2;
  };
  tick = function() {
    var time;
    time = (new Date).getTime();
    if (time - lastBeat >= (1000 / (bpm / 60)) - 3) {
      lastBeat = time;
      return beat();
    }
  };
  window.play = function() {
    return setInterval(tick, 1);
  };
  $(function() {
    var theGrid, theInstrument, theScale;
    console.log("here goes");
    theInstrument = instruments[0];
    theScale = scales["Major Pentatonic"];
    theGrid = new InstrumentGrid({
      instrument: theInstrument,
      scale: theScale
    });
    theGrid.render();
    return $(document.body).append(theGrid.el);
  });
}).call(this);
