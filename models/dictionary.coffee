Dictionary = (->
  mongoose = require 'mongoose'
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId
  pathSeparator = '#'


  ### schema ###
  _schema = new Schema
    name:
      type: String
      # unique: yes # can't be uniqued field, if same item has multiple parent

    parent:
      type: ObjectId
      set: (val) ->
        return val._id if typeof val is 'object' and val._id
        val
      index: yes

    idx:
      type: String
      # index: yes

    path:
      type: String
      index: yes

    dates:
      created:
        type: Date
        default: Date.now

      updated:
        type: Date
        default: Date.now

  ### hooks ###
  _schema.pre 'save', (next) ->
    # insert a date to dates every update or insert
    @dates.created = new Date() if @isNew
    @dates.updated = new Date()

    # check is parent object modfied
    isParentChange = @isModified 'parent'

    # check is this new object
    if @isNew or isParentChange
      # if this document has no parent set the path to itself
      if !@parent
        @path = @_id.toString()
        return next()

      self = @

      # find all ancestors and cocat their _id as "path"
      @collection.findOne
        _id: @parent
      , (err, doc) ->
        return next err if err

        previousPath = self.path
        self.path = doc.path + pathSeparator + self._id.toString()

        # When the parent is changed we must rewrite all children paths as well
        if isParentChange
          self.collection.find
            path:
              '$regex': "^#{previousPath}#{pathSeparator}"
          , (err, cursor) ->
            return next err if err

            stream = cursor.stream()
            stream.on 'data', (doc) ->
              newPath = self.path + doc.path.substr(previousPath.length)
              self.collection.update
                _id: doc._id
              ,
                $set:
                  path: newPath
              , (err) ->
                return err if err

            stream.on 'close', -> next()
            stream.on 'error', -> next err

        else
          next()
    else
      next()

  _schema.pre 'remove', (next) ->
    return next() if !@path
    @collection.remove
      path:
        '$regex': "^#{@path}#{pathSeparator}"
    , next


  ### methods ###
  _schema.method 'getChildren', (recursive, cb) ->
    if typeof recursive is 'function'
      cb = recursive
      recursive = no

    filter = if recursive then path: '$regex': "^#{@path}#{pathSeparator}" else parent: @_id
    @model(@constructor.modelName).find filter, cb


  _schema.method 'getParent', (cb) ->
    @model(@constructor.modelName).findOne _id: @parent, cb


  getAncestors = (cb) -> # get all ancestors
    if @path
      ids = @path.split pathSeparator
      ids.pop()
    else
      ids = []

    filter = _id : $in : ids

    @model(@constructor.modelName).find filter, cb

  _schema.method 'getAnsestors', getAncestors
  _schema.method 'getAncestors', getAncestors


  # register model
  _model = mongoose.model 'Dictionary', _schema


  {
    schema: _schema
    model: _model
  }

)()


module.exports = Dictionary
