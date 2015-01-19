# @file express.coffee
# @brief Initialises and configures express
# @author Oscar Bezi, oscar@bezi.io
# @since 7 January 2015
#===============================================================================
web = {}
express = require 'express'

morgan = require 'morgan'
bodyParser = require 'body-parser'
session = require 'express-session'
MongoStore = require 'connect-mongo'
MongoStore = MongoStore session

# @TODO: set up and use multer for file upload
# initialisation function
web.init = (config, callback) ->
    delete web.init
    web.express = express()
    web.express.set 'trust proxy', 1

    # session
    mongoStore = new MongoStore
            url: config.db.url

    web.express.use session
            secret: config.auth.secret
            resave: true
            saveUninitialized: false
            cookie:
                secure: false
            store: mongoStore

    web.express.use morgan 'dev'
    web.express.use bodyParser.urlencoded
            extended: true

    callback()

module.exports = web
