mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId
config = require './config'
async = require 'async'
Dictionary = require './models/dictionary'
app = require './app'
http = require 'http'
logger = require './config/log'


# connect to MongoDB
mongoose.connect config.mongodb.connect
mongoose.set 'debug', false
console.log "Connect to #{config.mongodb.connect}"


# migrate database
db = require('./db/conkey_db.json')

async.eachLimit db, 1, (doc, cb) -> # limit 5 iterators to run at any time
  # find is this document existing
  Dictionary.model.findOne _id: ObjectId(doc._id.$oid), (err, d) ->
    return logger.error(err) if err?

    # return if this document existing otherwise create a new document
    return cb() if d?

    d = new Dictionary.model
      name: doc.name
      _id: ObjectId(doc._id.$oid)
      path: doc.path
      dates: doc.dates
      idx: doc.idx

    d.parent = ObjectId(doc.parent.$oid) if doc.parent?

    process.nextTick -> d.save cb

, (err) ->
  return logger.error(err) if err?

  # start express server
  http.createServer(app).listen app.get('port'), ->
    console.log "HTTP server listening on port: #{app.get('port')}"
