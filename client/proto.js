(function() {
  var Instrument, Jam, JamView, PartView, PitchedInstrument, Player, _i, _results;
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
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.scales = {
    "Major Pentatonic": [0, 2, 4, 7, 9]
  };
  Instrument = (function() {
    function Instrument(key, name) {
      this.key = key;
      this.name = name;
    }
    Instrument.prototype.filename = function(soundKey, format) {
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
  window.instruments = {
    epiano: new PitchedInstrument("epiano", "E-Piano", (function() {
      _results = [];
      for (_i = 36; _i <= 69; _i++){ _results.push(_i); }
      return _results;
    }).apply(this, arguments))
  };
  Jam = (function() {
    __extends(Jam, Backbone.Model);
    function Jam() {
      Jam.__super__.constructor.apply(this, arguments);
    }
    Jam.prototype.defaults = {
      parts: {},
      scale: "Major Pentatonic",
      patternLength: 16,
      speed: 280,
      parts: {
        epiano: [[36, 40], [38, 43], [40, 45], [43, 48], [45, 50], [48, 52], [50, 55], [52, 57], [55, 60], [57, 62], [60, 64], [62, 67], [64, 69], [67, 36], [69, 67], [69, 36]]
      }
    };
    Jam.prototype.setPart = function(instrumentKey, part) {
      var parts;
      parts = this.get("parts");
      parts[instrumentKey] = part;
      return this.set("parts", parts);
    };
    Jam.prototype.getPart = function(instrumentKey) {
      return this.get("parts")[instrumentKey] || [];
    };
    return Jam;
  })();
  JamView = (function() {
    __extends(JamView, Backbone.View);
    function JamView() {
      JamView.__super__.constructor.apply(this, arguments);
    }
    JamView.prototype.render = function() {
      return $(this.el).html("ahem...");
    };
    return JamView;
  })();
  PartView = (function() {
    __extends(PartView, Backbone.View);
    function PartView() {
      PartView.__super__.constructor.apply(this, arguments);
    }
    PartView.prototype.className = "part";
    PartView.prototype.events = {
      "click TD": "toggleCell"
    };
    PartView.prototype.render = function() {
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
    PartView.prototype.toggleCell = function(event) {
      return $(event.target).toggleClass('on');
    };
    return PartView;
  })();
  Player = (function() {
    Player.prototype.format = "wav";
    Player.prototype.tickInterval = 5;
    Player.prototype.samplePolyphony = 2;
    function Player() {
      this.samples = {};
      this.state = "unprepared";
      console.log("Player feels woefully unprepared");
    }
    Player.prototype.loadJam = function(jam) {
      this.beatInterval = 1000 / (jam.get('speed') / 60);
      this.patternLength = jam.get('patternLength');
      this.scale = window.scales[jam.get('scale')];
      this.stageParts(jam.get('parts'));
      console.log("Player loaded jam");
      return this.prepare();
    };
    Player.prototype.prepare = function(callback) {
      var audioEl, filename, instrument, key, note, num, _j, _len, _ref, _ref2;
      this.prepareCallback = callback;
      _ref = window.instruments;
      for (key in _ref) {
        instrument = _ref[key];
        _ref2 = instrument.notesForScale(this.scale);
        for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
          note = _ref2[_j];
          filename = instrument.filename(note, this.format);
          this.samples[filename] = (function() {
            var _ref3, _results2;
            _results2 = [];
            for (num = 1, _ref3 = this.samplePolyphony; 1 <= _ref3 ? num <= _ref3 : num >= _ref3; 1 <= _ref3 ? num++ : num--) {
              audioEl = $('<audio />').attr('src', filename).data('state', 'loading');
              audioEl.bind('canplaythrough', __bind(function(ev) {
                var sample;
                sample = $(ev.target);
                sample.data('state', 'ready').unbind();
                console.log("Player loaded " + ev.target.src + "!");
                sample.bind('ended', function(ev) {
                  return $(ev.target).data('state', 'ready');
                });
                if (this.numSamplesLoading() === 0) {
                  this.state = 'ready';
                  console.log("Player ready");
                  if (this.prepareCallback != null) {
                    return this.prepareCallback();
                  }
                }
              }, this));
              console.log("Player loading " + filename);
              _results2.push(audioEl[0]);
            }
            return _results2;
          }).call(this);
        }
      }
      return this.state = "preparing";
    };
    Player.prototype.numSamplesLoading = function() {
      var el;
      return ((function() {
        var _j, _len, _ref, _results2;
        _ref = _.flatten(this.samples);
        _results2 = [];
        for (_j = 0, _len = _ref.length; _j < _len; _j++) {
          el = _ref[_j];
          if ($(el).data('state') === 'loading') {
            _results2.push(1);
          }
        }
        return _results2;
      }).call(this)).length;
    };
    Player.prototype.readyElementForSample = function(filename) {
      var el, _j, _len, _ref;
      _ref = this.samples[filename];
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        el = _ref[_j];
        if ($(el).data('state') === 'ready') {
          return el;
        }
      }
      console.log("Player sample elements exhausted for " + filename);
      return null;
    };
    Player.prototype.stageParts = function(parts) {
      this.stagedParts = parts;
      return console.log("Player staged new parts");
    };
    Player.prototype.beginPattern = function() {
      console.log("Player beginning pattern");
      this.patternPos = 0;
      if (this.stagedParts != null) {
        console.log("Player moved staged parts to main");
        this.parts = this.stagedParts;
        return this.stagedParts = null;
      }
    };
    Player.prototype.tick = function() {
      var time;
      time = (new Date).getTime();
      if (time - this.lastBeat >= this.beatInterval) {
        this.lastBeat = time;
        return this.beat();
      }
    };
    Player.prototype.beat = function() {
      var instrument, instrumentKey, needsPlaying, note, part, sample, _ref, _results2;
      console.log("Player: beat! pos = " + this.patternPos);
      this.patternPos += 1;
      if (this.patternPos === this.patternLength) {
        this.beginPattern();
      }
      _ref = this.parts;
      _results2 = [];
      for (instrumentKey in _ref) {
        part = _ref[instrumentKey];
        instrument = window.instruments[instrumentKey];
        _results2.push((function() {
          var _j, _len, _ref2, _results3;
          _ref2 = part[this.patternPos];
          _results3 = [];
          for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
            note = _ref2[_j];
            _results3.push((sample = this.readyElementForSample(instrument.filename(note, this.format))) ? ($(sample).data('state', 'playing'), needsPlaying = sample.currentTime === 0, sample.currentTime = 0, needsPlaying ? sample.play() : void 0) : void 0);
          }
          return _results3;
        }).call(this));
      }
      return _results2;
    };
    Player.prototype.play = function() {
      if (this.state !== "ready") {
        console.log("Player can't play in this state");
        return;
      }
      this.state = "playing";
      console.log("Player playing");
      this.beginPattern();
      this.lastBeat = 0;
      return this.tickIntervalID = setInterval(__bind(function() {
        return this.tick();
      }, this), this.tickInterval);
    };
    Player.prototype.stop = function() {
      if (this.state !== "playing") {
        console.log("Player can't stop - it isn't playing");
        return;
      }
      this.state = "ready";
      return clearInterval(this.tickIntervalID);
    };
    return Player;
  })();
  $(function() {
    console.log("here goes");
    window.player = new Player;
    window.jam = new Jam;
    return window.player.loadJam(window.jam);
  });
}).call(this);
