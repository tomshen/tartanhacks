# @file routes.coffee
# @brief Initalises the routes of the app.
# @author Oscar Bezi, oscar@bezi.io
# @since 8 January 2015
#===============================================================================
routes = {}
routes.init = (app, models, auth, config, callback) ->
    delete routes.init

    # /login and /logout
    routes.auth = require('./auth')(app, models, auth)

    # /me and /users
    routes.users = require('./users')(app, models, auth)

    # /register and /openStatus
    routes.register = require('./register')(app, models, auth)

    callback()

module.exports = routes
