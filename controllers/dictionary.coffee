logger = require '../config/log'
config = require '../config'
ObjectId = (require 'mongoose').Types.ObjectId
Dictionary = require '../models/dictionary'

dictionaryController =

  # @get /dict
  # @return [{id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}]
  index: (req, res) ->
    query = Dictionary.model.find parent: null, (err, dicts) ->
      if err
        logger.error err
        return res.json 500, error: err

      data = results: dicts

      res.json data


  # @get /dict
  # @return {id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}
  show: (req, res) ->
    dict = req.dictionary

    if !req.dictionary?
      return res.json 404, error: 'Not found'

    res.json
      results: [dict]


  # @post /dict {t: String, parent: String(ObjectID)}
  # @return {id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}
  create: (req, res) ->
    if !req.body.hasOwnProperty('t')
      return res.json 400, error: 'Error 400: Post syntax incorrent.'

    name = req.body.t
    parent = if req.body.parent then new ObjectId(req.body.parent) else null

    dict = new Dictionary.model
      name: name
      parent: parent

    dict.save (err) ->

      if err
        logger.error err
        return res.json 500, error: err

      res.json
        results: [dict]

  # @put /dict/:dict {t: String, parent: String(ObjectID)}
  # @return {id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}
  update: (req, res) ->
    if !req.body.hasOwnProperty('t')
      res.statusCode = 400
      return res.json error: 'Error 400: Post syntax incorrent.'

    if !req.dictionary?
      return res.json 404, error: 'Not found'

    dict = req.dictionary
    dict.name = req.body.t if req.body.t
    dict.parent = if req.body.parent then new ObjectId(req.body.parent) else null
    dict.save (err) ->

      if err
        logger.error err
        res.statusCode = 500
        return res.json error: err

      res.json
        results: [dict]


  # @delete /dict/:dict
  # @return true
  delete: (req, res) ->
    if !req.dictionary?
      return res.json 404, error: 'Not found'

    dict = req.dictionary
    dict.remove (err) ->

      if err
        logger.error err
        return res.json 500, error: err

      res.json true

  # @get /dict/:dict/parents
  # @return [{id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}]
  getParents: (req, res) ->
    dict = req.dictionary

    if !req.dictionary?
      return res.json 404, error: 'Not found'

    dict.getAnsestors (err, parents) ->

      if err
        logger.error err
        return res.json 500, error: err

      res.json
        results: parents


  # @get /dict/:dict/children
  # @return [{id: String(ObjectID), t: String, parent: String(ObjectID), path: String, dates: {updated: Datetime, create: Datetime}}]
  getChildren: (req, res) ->
    dict = req.dictionary

    if !req.dictionary?
      return res.json 404, error: 'Not found'

    dict.getChildren  (err, children) ->
      if err
        logger.error err
        return res.json 500, error: err

      res.json
        results: children


module.exports = dictionaryController
