# mocha -R spec --compilers coffee:coffee-script

should = require 'should'
mongoose = require 'mongoose'
async = require 'async'
logger = require '../config/log'
Schema = mongoose.Schema
ObjectId = mongoose.Types.ObjectId
config = require '../config'


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
    , done


removeDummyDictionary = (done) -> # remove the user after finish all testing tasks
  mongoose.connection.collections['dictionaries'].drop (err) ->
    return done err if err
    # Disconnecting mongodb
    mongoose.connection.close done


### tests ###
describe 'model', ->

  # dictionary
  describe 'dictionary', ->
    before createDummyDictionary
    after removeDummyDictionary

    it 'should set parent id and path', (done) ->
      Dictionary.model.find({}
      , (err, docs) ->
        should.not.exist err

        tree = {}
        tree[doc.name] = doc for doc in docs

        # should has parent
        should.not.exist tree['A'].parent
        tree['B'].parent.toString().should.equal tree['A']._id.toString()
        tree['C'].parent.toString().should.equal tree['A']._id.toString()
        tree['D'].parent.toString().should.equal tree['C']._id.toString()
        tree['E'].parent.toString().should.equal tree['C']._id.toString()

        # should has path
        tree['A'].path.should.equal tree['A']._id.toString()
        tree['B'].path.should.equal "#{tree['A']._id.toString()}##{tree['B']._id.toString()}"
        tree['C'].path.should.equal "#{tree['A']._id.toString()}##{tree['C']._id.toString()}"
        tree['D'].path.should.equal "#{tree['A']._id.toString()}##{tree['C']._id.toString()}##{tree['D']._id.toString()}"
        tree['E'].path.should.equal "#{tree['A']._id.toString()}##{tree['C']._id.toString()}##{tree['E']._id.toString()}"

        done()
      )

    it 'should remove related childen', (done) ->
      Dictionary.model.findOne
        name: 'C'
      , (err, doc) ->
        should.not.exist err

        doc.getChildren true, (err, docs) ->
          docs.length.should.equal 2 # should has 2 records ['A', 'C']

          Dictionary.model.findByIdAndRemove doc._id, (err) ->
            should.not.exist err

            Dictionary.model.find
              '$regex': "^#{doc._id}#"
            , (err, docs) ->
              should.not.exist err
              docs.length.should.equal 0

              done()
