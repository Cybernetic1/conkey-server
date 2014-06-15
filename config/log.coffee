winston = require 'winston'
env = process.env.ENV_VARIABLE or 'test'
now = new Date()
date = now.toJSON()

winston.add(
  winston.transports.File, {
    filename: "logs/#{env}.log"
  }
)

winston.log 'info', "LOG BEGINNING - #{date}"

module.exports = winston