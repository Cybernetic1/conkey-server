logger = require './config/log'
ObjectId = (require 'mongoose').Types.ObjectId
Dictionary = require './models/dictionary'
dictionaryController = require './controllers/dictionary'
config = require './config'

crossBrowser = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Allow-Headers', 'X-Requested-With'
  next()

router = (app) ->

  ### dictonaryController ###

  app.get '/dict', crossBrowser, dictionaryController.index

  app.get '/dict/:dict', crossBrowser, dictionaryController.show

  app.post '/dict', crossBrowser, dictionaryController.create

  app.put '/dict/:dict', crossBrowser, dictionaryController.update

  app.delete '/dict/:dict', crossBrowser, dictionaryController.delete

  app.get '/dict/:dict/parents', crossBrowser, dictionaryController.getParents

  app.get '/dict/:dict/children', crossBrowser, dictionaryController.getChildren


  ### express param ###
  app.param 'dict', (req, res, next, dict) ->
    if dict.match(/^[0-9a-fA-F]{24}$/)
      Dictionary.model.findOne
        _id: dict
      , (err, doc) ->
        if err
          logger.error err
          return next err

        if doc
          req.dictionary = doc
          next()
        else
          next(new Error('failed to load dictionary'))
    else
      req.dictionary = null
      next()


module.exports = router
