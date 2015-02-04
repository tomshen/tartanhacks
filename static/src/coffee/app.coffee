# @file app.coffee
# @brief Implements the logic for the TH app in various sections
#===============================================================================
window.app = {}

#===============================================================================
# 3rd Party Setup
#===============================================================================

# particlesJS
#============
app.particlesJS = ->
    console.log 'particles'
    particlesJS 'splash-bg',
        particles:
            color: '#fff',
            shape: 'triangle',
            opacity: 1,
            size: 2,
            size_random: false,
            nb: $(window).width() / 10,
            line_linked:
                enable_auto: true,
                distance: 100,
                color: '#fff',
                opacity: 0.9,
                widapp: 1,
                condensed_mode:
                    enable: false,
                    rotateX: 600,
                    rotateY: 600
            anim:
                enable: true,
                speed: 1
        interactivity:
            enable: false
        # Retina Display Support
        retina_detect: true

# Handlebars
#===========
Handlebars.registerHelper 'if_cond', (v1, operator, v2, options)->
    switch operator
        when '==', '==='
            return if v1 is v2 then options.fn @ else options.inverse @
        when '<'
            return if v1 < v2 then options.fn @ else options.inverse @
        when '<='
            return if v1 <= v2 then options.fn @ else options.inverse @
        when '>'
            return if v1 > v2 then options.fn @ else options.inverse @
        when '>='
            return if v1 >= v2 then options.fn @ else options.inverse @
        when '&&'
            return if v1 && v2 then options.fn @ else options.inverse @
        when '||'
            return if v1 || v2 then options.fn @ else options.inverse @
        else
            return options.inverse @

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

#===============================================================================
# Navbar
#===============================================================================
$('#navbar').on 'click', () -> $('#navbar').toggleClass 'active'

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
                app.router()
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
                next user
            .fail app.err
    else
        app.err()

# @function set_me
# @brief PUTs /api/me and runs the callback
app.api.set_me = (user, next) ->
    if app.profile.loggedIn
        $.ajax
                type: 'PUT'
                url: '/api/me'
                data: user
            .done ->
                next()
            .fail app.err
    else
        app.err()

# @function delete_me
# @brief DELETE /api/me and runs the callback
app.api.delete_me = (next) ->
    if app.profile.loggedIn
        $.ajax
                type: 'DELETE'
                url: '/api/me'
            .done ->
                app.api.logout next
            .fail app.err
    else
        app.err()

# @function register_me
# @brief Registers a user for TartanHacks.  Does not guarantee a spot
app.api.register_me = (data, next) ->
    if app.profile.loggedIn
        $.ajax
                type: 'POST'
                url: '/api/register'
                data: data
            .done ->
                app.router()
            .fail app.err
    else
        app.err()

# @function register_status
# @brief Returns information regarding registration
app.api.register_status = (next) ->
    $.get '/api/openStatus', null
        .done (status) ->
            status = JSON.parse status
            next status
        .fail app.err

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
        when 'about' then app.routes.about()

        when 'profile' then app.routes.profile()
        when 'profile/edit' then app.routes.profile edit: true

        when 'register' then app.routes.register()
        when 'register/priority' then app.routes.register priority: true

        when 'schedule' then app.routes.schedule()
        when 'faq' then app.routes.faq()

        when '' then app.routes.home()
        else app.routes.err404 route

# set event listener
$(window).on 'hashchange', app.router

# on document load, run router
$(app.router)

#===============================================================================
# About
#===============================================================================
app.templates.about = Handlebars.compile $('#about-template').html()
app.routes.about = -> $('#content').html app.templates.about()

#===============================================================================
# Profile
#===============================================================================
app.profile = {}

app.profile.loggedIn = false

# @function formHandler
# @brief Serializes form, uploads the value, then redirects to /profile
app.profile.formHandler = (e) ->
    user = $('#profile-form').serialize()
    app.api.set_me user, -> location.href = '/#/profile/'
    e.preventDefault()

# @function deleteBtnHandler
# @brief Basic validation that the user really wants to delete their profile
app.profile.deleteBtnHandler = (e) ->
    if $('#profile-delete-text').val() is 'delete'
        app.api.delete_me()

app.templates.profile = Handlebars.compile $('#profile-template').html()

# @function app.routes.profile
# @brief Reloads the profile div.  The options object can have one parameter,
# 'edit', which is true if we want to edit the page.
app.routes.profile = (options) ->
    options ?= {}
    options.loggedIn = app.profile.loggedIn
    if not options.loggedIn
        $('#content').html app.templates.profile options
        app.google.renderBtn()
    else
        app.api.get_me (user) ->

            # if the user is functionally empty, delete it so we can display
            # a better message on the client
            delete user.isAccepted
            delete user.isCheckedIn
            delete user.isRegistered

            Object.keys(user).map (key) ->
                if not user[key]? or user[key] is ""
                    delete user[key]

            if Object.keys(user).length isnt 0
                options.user = user

            $('#content').html app.templates.profile options

            # various button handlers

            # delete button
            $('#profile-delete').on 'click', app.profile.deleteBtnHandler

            if options.edit
                # edit form handler
                # mobile can usually submit form without hitting button
                $('#profile-form').submit app.profile.formHandler

                # everyone else
                $('#profile-form-submit').on 'click', app.profile.formHandler
            else
                # logout button
                $('#logout').on 'click', app.api.logout

#===============================================================================
# Register
#===============================================================================
app.register = {}

# @function formHandler
# @brief Serializes form, uploads the value, then redirects to /profile
app.register.formHandler = (e) ->
    data = $('#register-form').serialize()
    app.api.register_me data, -> app.router()
    e.preventDefault()

app.templates.register = Handlebars.compile $('#register-template').html()

# @function app.routes.register
# @brief Reloads the registration div.  The options object can have one
# parameter, 'priority', if the person has consciously navigated to the priority
# queue
app.routes.register = (options) ->
    app.api.register_status (data) ->
        options ?= {}
        options.status = data.status
        options.loggedIn = app.profile.loggedIn

        if options.loggedIn
            app.api.get_me (user) ->
                options.user = user
                $('#content').html app.templates.register options

                # mobile can usually submit form without hitting button
                $('#register-form').submit app.register.formHandler

                # everyone else
                $('#register-form-submit').on 'click', app.register.formHandler
        else
            $('#content').html app.templates.register options
            app.google.renderBtn()

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
# Schedule
#===============================================================================
app.templates.schedule = Handlebars.compile $('#schedule-template').html()
app.routes.schedule = -> $('#content').html app.templates.schedule()

#===============================================================================
# FAQ
#===============================================================================
app.templates.faq = Handlebars.compile $('#faq-template').html()
app.routes.faq = -> $('#content').html app.templates.faq()

#===============================================================================
# Home
#===============================================================================
app.templates.splash = Handlebars.compile $('#splash-template').html()
app.routes.home = ->
    $('#content').html app.templates.splash()
    app.particlesJS()
