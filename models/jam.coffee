
mongoose = require 'mongoose'
Schema = mongoose.Schema

JamSchema = new Schema {
  title:         String,
  created:       { type: Date, default: Date.now },
  creator:       Schema.ObjectId,
  artists:       [Schema.ObjectId],
  scale:         { type: String, default: "Minor Pentatonic" },
  patternLength: { type: Number, default: 16 },
  speed:         { type: Number, default: 280 },
  music:         { type: String, default: "{}" }
}

Jam = mongoose.model 'Jam', JamSchema
module.exports = Jam