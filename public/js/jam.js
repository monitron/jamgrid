(function() {
  var Instrument, Jam, JamView, PartView, PercussionInstrument, PitchedInstrument, Player, _i, _results;
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
    "Major Pentatonic": [0, 2, 4, 7, 9],
    "Minor Pentatonic": [0, 3, 5, 7, 10],
    "Chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  };
  Instrument = (function() {
    function Instrument(key, name) {
      this.key = key;
      this.name = name;
    }
    Instrument.prototype.filename = function(soundKey, format) {
      this.soundKey = soundKey;
      this.format = format;
      return "/instruments/" + this.key + "/" + this.soundKey + "." + this.format;
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
    PitchedInstrument.prototype.soundsForScale = function(scale) {
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
  PercussionInstrument = (function() {
    __extends(PercussionInstrument, Instrument);
    function PercussionInstrument(key, name, sounds) {
      this.key = key;
      this.name = name;
      this.sounds = sounds;
    }
    PercussionInstrument.prototype.iconFilename = function(soundKey) {
      this.soundKey = soundKey;
      return "/images/instruments/" + this.key + "/sounds/" + this.soundKey + ".png";
    };
    PercussionInstrument.prototype.soundsForScale = function(scale) {
      return this.sounds;
    };
    return PercussionInstrument;
  })();
  window.instruments = {
    epiano: new PitchedInstrument("epiano", "E-Piano", (function() {
      _results = [];
      for (_i = 28; _i <= 63; _i++){ _results.push(_i); }
      return _results;
    }).apply(this, arguments)),
    808: new PercussionInstrument("808", "808", ['bass', 'closedhat', 'openhat', 'snare', 'cymbal', 'clap', 'cowbell'])
  };
  Jam = (function() {
    __extends(Jam, Backbone.Model);
    function Jam() {
      Jam.__super__.constructor.apply(this, arguments);
    }
    Jam.prototype.defaults = {
      parts: {},
      scale: "Minor Pentatonic",
      patternLength: 16,
      speed: 280
    };
    Jam.prototype.setPart = function(instrumentKey, part) {
      var parts;
      parts = _.clone(this.get("parts"));
      parts[instrumentKey] = part;
      return this.set({
        parts: parts
      });
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
    JamView.prototype.initialize = function() {
      this.render();
      return this.editPart("epiano");
    };
    JamView.prototype.events = {
      "click .playButton": "play",
      "click .stopButton": "stop",
      "click .instruments li": "editPart"
    };
    JamView.prototype.editPart = function(instrumentKey) {
      if (instrumentKey.target != null) {
        instrumentKey = $(instrumentKey.target).data('key');
      }
      this.editingInstrument = instrumentKey;
      return this.partView = new PartView({
        jam: this.model,
        instrumentKey: instrumentKey,
        el: this.$('.part')
      });
    };
    JamView.prototype.play = function() {
      return window.player.play();
    };
    JamView.prototype.stop = function() {
      return window.player.stop();
    };
    JamView.prototype.render = function() {
      var buttons, instrument, instruments, key, _ref;
      instruments = $('<ul />').addClass('instruments');
      _ref = window.instruments;
      for (key in _ref) {
        instrument = _ref[key];
        instruments.append($('<li />').html(instrument.name).data('key', instrument.key));
      }
      buttons = $('<div />');
      buttons.append($('<button />').html('Play').addClass('playButton'));
      buttons.append($('<button />').html('Stop').addClass('stopButton'));
      $(this.el).html(instruments);
      $(this.el).append($('<div />').addClass('part'));
      return $(this.el).append(buttons);
    };
    return JamView;
  })();
  PartView = (function() {
    __extends(PartView, Backbone.View);
    function PartView() {
      PartView.__super__.constructor.apply(this, arguments);
    }
    PartView.prototype.initialize = function() {
      var _j, _ref, _results2;
      this.jam = this.options.jam;
      this.instrument = window.instruments[this.options.instrumentKey];
      this.scale = window.scales[this.jam.get("scale")];
      this.beats = (function() {
        _results2 = [];
        for (var _j = 0, _ref = this.jam.get('patternLength') - 1; 0 <= _ref ? _j <= _ref : _j >= _ref; 0 <= _ref ? _j++ : _j--){ _results2.push(_j); }
        return _results2;
      }).apply(this, arguments);
      this.sounds = this.instrument.soundsForScale(this.scale);
      this.render();
      this.setCells(this.jam.getPart(this.options.instrumentKey));
      return window.player.bind('beat', __bind(function(num) {
        return this.setCurrentBeat(num);
      }, this));
    };
    PartView.prototype.events = {
      "click TD.toggleable": "toggleCell",
      "click .clearButton": "resetPattern"
    };
    PartView.prototype.render = function() {
      var beat, container, row, sound, table, _j, _k, _len, _len2, _ref, _ref2;
      table = $('<table />');
      _ref = this.sounds;
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        sound = _ref[_j];
        row = $('<tr />');
        row.append($('<td />').html(sound).addClass('label'));
        _ref2 = this.beats;
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          beat = _ref2[_k];
          row.append($('<td />').attr('data-beat', beat).attr('data-sound', sound).addClass('toggleable'));
        }
        table.prepend(row);
      }
      container = $('<div />');
      container.append($('<h3 />').html('Edit ' + this.instrument.name));
      container.append(table);
      container.append($('<button />').html('Clear').addClass('clearButton'));
      return $(this.el).html(container);
    };
    PartView.prototype.toggleCell = function(event) {
      $(event.target).toggleClass('on');
      return this.updateModel();
    };
    PartView.prototype.resetPattern = function() {
      this.clearCells();
      return this.updateModel();
    };
    PartView.prototype.findCell = function(beat, sound) {
      return this.$("td[data-beat=" + beat + "][data-sound=" + sound + "]");
    };
    PartView.prototype.clearCells = function() {
      return this.$("td").removeClass('on');
    };
    PartView.prototype.setCells = function(part) {
      var beatNum, sound, sounds, _len, _results2;
      this.clearCells();
      _results2 = [];
      for (beatNum = 0, _len = part.length; beatNum < _len; beatNum++) {
        sounds = part[beatNum];
        _results2.push((function() {
          var _j, _len2, _results3;
          _results3 = [];
          for (_j = 0, _len2 = sounds.length; _j < _len2; _j++) {
            sound = sounds[_j];
            _results3.push(this.findCell(beatNum, sound).addClass('on'));
          }
          return _results3;
        }).call(this));
      }
      return _results2;
    };
    PartView.prototype.setCurrentBeat = function(beat) {
      this.$("td").removeClass('current');
      return this.$("td[data-beat=" + beat + "]").addClass('current');
    };
    PartView.prototype.updateModel = function() {
      var cell, n, part, _j, _len, _ref;
      part = (function() {
        var _ref, _results2;
        _results2 = [];
        for (n = 1, _ref = this.jam.get('patternLength'); 1 <= _ref ? n <= _ref : n >= _ref; 1 <= _ref ? n++ : n--) {
          _results2.push([]);
        }
        return _results2;
      }).call(this);
      _ref = this.$("td.on");
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        cell = _ref[_j];
        cell = $(cell);
        part[cell.data('beat')].push(cell.data('sound'));
      }
      return this.jam.setPart(this.options.instrumentKey, part);
    };
    return PartView;
  })();
  Player = (function() {
    Player.prototype.format = "wav";
    Player.prototype.tickInterval = 5;
    Player.prototype.samplePolyphony = 2;
    function Player() {
      _.extend(this, Backbone.Events);
      this.samples = {};
      this.state = "unprepared";
      console.log("Player feels woefully unprepared");
    }
    Player.prototype.loadJam = function(jam) {
      this.beatInterval = 1000 / (jam.get('speed') / 60);
      this.patternLength = jam.get('patternLength');
      this.scale = window.scales[jam.get('scale')];
      this.parts = jam.get('parts');
      jam.bind("change:parts", __bind(function() {
        return this.parts = jam.get("parts");
      }, this));
      console.log("Player loaded jam");
      return this.prepare();
    };
    Player.prototype.prepare = function(callback) {
      var audioEl, filename, instrument, key, num, sound, _j, _len, _ref, _ref2;
      _ref = window.instruments;
      for (key in _ref) {
        instrument = _ref[key];
        _ref2 = instrument.soundsForScale(this.scale);
        for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
          sound = _ref2[_j];
          filename = instrument.filename(sound, this.format);
          this.samples[filename] = (function() {
            var _ref3, _results2;
            _results2 = [];
            for (num = 1, _ref3 = this.samplePolyphony; 1 <= _ref3 ? num <= _ref3 : num >= _ref3; 1 <= _ref3 ? num++ : num--) {
              audioEl = $('<audio />').attr('src', filename).data({
                state: 'loading',
                n: num
              });
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
                  if (callback != null) {
                    return callback();
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
    Player.prototype.beginPattern = function() {
      console.log("Player beginning pattern");
      return this.patternPos = 0;
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
      var instrument, instrumentKey, needsPlaying, part, sample, sound, _j, _len, _ref, _ref2;
      console.log("Player: beat! pos = " + this.patternPos);
      if (this.patternPos === this.patternLength) {
        this.beginPattern();
      }
      _ref = this.parts;
      for (instrumentKey in _ref) {
        part = _ref[instrumentKey];
        instrument = window.instruments[instrumentKey];
        _ref2 = part[this.patternPos];
        for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
          sound = _ref2[_j];
          if (sample = this.readyElementForSample(instrument.filename(sound, this.format))) {
            $(sample).data('state', 'playing');
            needsPlaying = sample.currentTime === 0;
            sample.currentTime = 0;
            if (needsPlaying) {
              sample.play();
            }
          }
        }
      }
      this.trigger('beat', this.patternPos);
      return this.patternPos += 1;
    };
    Player.prototype.play = function() {
      if (this.state !== "ready") {
        console.log("Player isn't ready to play");
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
    if (!(window.console != null)) {
      window.console = {
        log: function() {}
      };
    }
    console.log("Initializing");
    window.player = new Player;
    window.jam = new Jam;
    window.player.loadJam(window.jam);
    return new JamView({
      model: window.jam,
      el: $('#jam')[0]
    });
  });
}).call(this);
