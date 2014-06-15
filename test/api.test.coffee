# mocha -R spec --compilers coffee:coffee-script

should = require 'should'
request = require 'superagent'
mongoose = require 'mongoose'
async = require 'async'
logger = require '../config/log'
Schema = mongoose.Schema
ObjectId = mongoose.Types.ObjectId
http = require 'http'
app = require process.cwd() + '/app.coffee'
config = require '../config'
server = null


### models ###
Dictionary = require '../models/dictionary'


createDummyDictionary = (done) -> # creates a dummy tree
  mongoose.set 'debug', false
  mongoose.connect config.mongodb.connect, ->

    #            A       
    #           / \
    #          B   C
    #             / \
    #            D   E
    
    a = new Dictionary.model { name: 'A' }
    b = new Dictionary.model { name: 'B', parent: a }
    c = new Dictionary.model { name: 'C', parent: a }
    d = new Dictionary.model { name: 'D', parent: c }
    e = new Dictionary.model { name: 'E', parent: c }

    async.eachSeries [a, b, c, d, e], (doc, cb) ->
      doc.save cb
    , ->
      # start express server
      server = http.createServer(app).listen app.get('port'), done



removeDummyDictionary = (done) -> # remove the user after finish all testing tasks
  mongoose.connection.collections['dictionaries'].drop (err) ->
    return done err if err

    # Disconnecting mongodb
    mongoose.connection.close ->
      # Closing express server
      server.close done


### Restful API ###
describe 'api', ->

  # dictionary
  describe 'dictionary', ->
    before createDummyDictionary
    after removeDummyDictionary


    it 'should get root level nodes', (done) ->
      request
        .get("localhost:3000/dict")
        .end (res) ->
          res.ok.should.equal yes
          should.exist res
          res.body.results.length.should.equal 1
          res.body.results[0].name.should.equal 'A'

          done()


    it 'should get a "A"', (done) ->
      # Find the "A" in mongodb and send a ajax requst with the id
      Dictionary.model.findOne 
        name: 'A'
      , (err, a) ->
        should.not.exist err
        should.exist a

        request
          .get("localhost:3000/dict/#{a._id}")
          .set('Accept', 'application/json')
          .end (res) ->
            res.ok.should.equal yes
            should.exist res
            res.body.results[0].name.should.equal 'A'
            done()


    it 'should get a children of "A"', (done) ->
      # Find the "A" in mongodb and send a ajax requst with the id
      Dictionary.model.findOne
        name: 'A'
      , (err, a) ->
        should.not.exist err
        should.exist a

        request
          .get("localhost:3000/dict/#{a._id}/children")
          .set('Accept', 'application/json')
          .end (res) ->
            res.ok.should.equal yes
            should.exist res
            res.body.results.length.should.equal 2
            res.body.results[0].name.should.match ///^[C,B]$///i # first result should match "C" or "B"
            done()


    it 'should get a parents of "B"', (done) ->
      # Find the "B" in mongodb and send a ajax requst with the id
      Dictionary.model.findOne
        name: 'B'
      , (err, b) ->
        should.not.exist err
        should.exist b

        request
          .get("localhost:3000/dict/#{b._id}/parents")
          .set('Accept', 'application/json')
          .end (res) ->
            res.ok.should.equal yes
            should.exist res
            res.body.results.length.should.equal 1
            res.body.results[0].name.should.equal 'A'
            done()


    it 'should update "A" to "A01" and parent should change to "B"', (done) ->
      # Find the "A" in mongodb and send a ajax requst with the id
      Dictionary.model.findOne
        name: 'A'
      , (err, a) ->
        should.not.exist err
        should.exist a

        Dictionary.model.findOne
          name: 'B'
        , (err, b) ->
          should.not.exist err
          should.exist b

          data =
            t: "A01"
            parent: b._id

          request
            .put("localhost:3000/dict/#{a._id}")
            .send(data)
            .set('Accept', 'application/json')
            .end (res) ->
              res.ok.should.equal yes
              should.exist res
              res.body.results[0].name.should.equal 'A01'
              res.body.results[0].parent.should.equal b._id.toString()
              done()


    it 'should remove "C"', (done) ->
      # Find the "C" in mongodb and send a ajax requst with the id
      Dictionary.model.findOne
        name: 'C'
      , (err, c) ->
        should.not.exist err
        should.exist c

        request
          .del("localhost:3000/dict/#{c._id}")
          .end (res) ->
            res.ok.should.equal yes
            should.exist res
            res.body.should.equal yes

            Dictionary.model.findOne
              name: 'C'
            , (err, c) ->
              should.not.exist err
              should.not.exist c
              done()

