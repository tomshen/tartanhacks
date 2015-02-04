# @file admin.coffee
# @brief Implements for the TH admin panel
#===============================================================================
window.app = {}


# googleAPI
#==========
app.google = {}

# @function app.google.render
# @brief Checks the Google Sign in with an invisible div
app.google.render = ->
    gapi.signin.render 'googleSignIn',
            callback: 'signInCallback'
            clientid: '70162173884-17kl5i9qdhkj5qbrj3ds4bpg573dg5h0.apps.googleusercontent.com'
            cookiepolicy: 'single_host_origin'
            scope: 'profile'

# @function app.google.renderBtn
# @brief Sets the click handler of the Google Sign In button to perform the
# Google Oauth authentication
app.google.renderBtn = ->
    if gapi?
        gapi.signin.render 'googleSignInBtn',
                callback: 'signInCallback'
                clientid: '70162173884-17kl5i9qdhkj5qbrj3ds4bpg573dg5h0.apps.googleusercontent.com'
                cookiepolicy: 'single_host_origin'
                scope: 'profile'
    else
        # cannot guarantee GAPI will be loaded if this is called
        # let it load.  Check every 0.1s until it is loaded
        setTimeout app.google.renderBtn, 100

# @function app.google.callback
# @brief Runs the response code from the Google callback through our login
# handler.
app.google.callback = (res) ->
    $('#googleSignIn').hide()
    if res.code? then app.api.login res.code else app.err()

# load google API immediately
(() ->
    # the Google API requires global functions
    window.render = app.google.render
    window.signInCallback = app.google.callback

    po = document.createElement 'script'
    po.type = 'text/javascript'
    po.async = true
    po.src = 'https://apis.google.com/js/client:plusone.js?onload=render'
    s = document.getElementsByTagName('script')[0]
    s.parentNode.insertBefore po, s
)()
#
#===============================================================================
# API
#===============================================================================
app.api = {}

# @function login
# @brief Given the OAuth single use token, performs an API query and logs in
# the user
app.api.login = (code) ->
    if not app.profile.loggedIn
        $.post '/api/login', singleUseToken: code
            .done (res) ->
                app.profile.loggedIn = true
                app.api.get_me app.router
            .fail app.err
    else
        app.err()

# @function logout
# @brief Logs the user out
app.api.logout = () ->
    if app.profile.loggedIn
        $.get '/api/logout', null
            .done () ->
                app.profile.loggedIn = false
                app.router()
            .fail app.err
    else
        app.err()

# @function get_me
# @brief GETs /api/me and passes the data to next()
app.api.get_me = (next) ->
    if app.profile.loggedIn
        $.get '/api/me', null
            .done (user) ->
                user = JSON.parse user
                app.profile.isAdmin = user.isAdmin? and user.isAdmin
                next user
            .fail app.err
    else
        app.err()

# @function get_users
# @brief Gets the userlist
app.api.get_users = (next) ->
    if app.profile.isAdmin
        $.get '/api/users', null
            .done (users) ->
                users = JSON.parse users
                next users
            .fail app.err
    else
        app.err()

# @function delete_user
# @brief Deletes a user
app.api.delete_user = (userID, next) ->
    if app.profile.isAdmin
        $.ajax
            url: "/api/users/#{ userID }"
            type: 'DELETE'
            success: (result) -> next(result)

# @function accept_user
# @brief Accepts a user
app.api.accept_user = (userID, next) ->
    if app.profile.isAdmin
        $.ajax
            url: "/api/users/#{ userID }"
            type: 'PUT'
            data: isAccepted: true
            success: (result) -> next(result)

# @function checkin_user
# @brief Checks in a user
app.api.checkin_user = (userID, next) ->
    if app.profile.isAdmin
        $.ajax
            url: "/api/users/#{ userID }"
            type: 'PUT'
            data: isCheckedIn: true
            success: (result) -> next(result)

# @function register_status
# @brief Returns information regarding registration
app.api.register_status = (next) ->
    $.get '/api/openStatus', null
        .done (status) ->
            status = JSON.parse status
            next status
        .fail app.err

#===============================================================================
# Profile
#===============================================================================
app.profile = {}
app.profile.loggedIn = false
app.profile.isAdmin = false

#===============================================================================
# Router
#===============================================================================
app.routes = {}
app.templates = {}

app.router = ->
    route = location.hash[1..]

    # strip leading / and trailing / if there is one
    route = route.replace /^\//, ''
    route = route.replace /\/$/, ''

    switch route
        when '' then app.routes.home()
        when 'user-list' then app.routes.userlist()
        when 'hacker-list' then app.routes.hackerlist()
        else app.routes.err404 route

# set event listener
$(window).on 'hashchange', app.router

# on document load, run router
$(app.router)

#===============================================================================
# Login
#===============================================================================
app.templates.login = Handlebars.compile $('#login-template').html()

#===============================================================================
# Homepage
#===============================================================================
app.templates.home = Handlebars.compile $('#home-template').html()
app.routes.home = ->
    if app.profile.isAdmin
            $('#content').html app.templates.home()
        else
            $('#content').html app.templates.login()

#===============================================================================
# Error Handlers
#===============================================================================
app.templates.err = Handlebars.compile $('#error-template').html()
app.routes.err = ->
    $('#content').html app.templates.err()
    app.router()

app.templates.err404 = Handlebars.compile $('#error-404-template').html()
app.routes.err404 = (addr) -> $('#content').html app.templates.err404 addr: addr

app.err = app.routes.err

#===============================================================================
# Lists
#===============================================================================
app.lists = {}

app.lists.acceptHandler = (id) ->
    app.api.accept_user id, () ->
        app.router()
    return false

app.lists.deleteHandler = (id) ->
    app.api.delete_user id, () ->
        app.router()
    return false

app.lists.checkinHandler = (id) ->
    app.api.checkin_user id, () ->
        app.router()
    return false

app.templates.hackerlist = Handlebars.compile $('#hacker-list-template').html()
app.routes.hackerlist = ->
    app.api.get_users (users) ->
        users = users.filter (elem) ->
            elem.isAccepted? and elem.isAccepted
        $('#content').html app.templates.hackerlist users: users

app.templates.userlist = Handlebars.compile $('#user-list-template').html()
app.routes.userlist = ->
    app.api.get_users (users) ->
        users = users.filter (elem) ->
            not ((elem.isAdmin? and elem.isAdmin) or (elem.isMentor? and elem.isMentor) or (elem.isAccepted? and elem.isAccepted))
        $('#content').html app.templates.userlist users: users
