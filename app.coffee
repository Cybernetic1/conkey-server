express = require 'express'

app = express()

app.set 'port', process.env.PORT || 3000

# express.bodyParser() is deprecate in connect 3.0
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()


# routes
require('./routes') app

module.exports = app
