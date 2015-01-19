# @file register.coffee
# @brief Implements the registration end points at /register and /openStatus
# @author Oscar Bezi, oscar@bezi.io
# @since 19 January 2015
#===============================================================================

models = null

# how many 'regular' spots there are
regularSpots = 315

spotsTaken = (next) ->
    models.User.count
            isAccepted: true
        , (err, count) ->
            next err, count

spotsRemaining = (next) ->
   spotsTaken (err, count) -> next err, Math.max regularSpots - count, 0

spotsAvailable = (next, none) ->
    spotsRemaining (err, count) ->
        if err?
            none err
        else if count is 0
            none()
        else
            next()

# @TODO: enclose this in a private variable
openStatus = 'closed'

setOpenStatus = (status, next) ->
    if status in ['closed', 'priority', 'open']
        openStatus = status
        next()
    else
        next 'Invalid status code'

getOpenStatus = -> openStatus

module.exports = (app, dbModels, auth) ->
    models = dbModels

    # GET /openStatus
    app.route '/openStatus'
        .get (req, res) ->
            auth.isAdmin req, res, () ->
                    spotsTaken (err, count) ->
                        if err?
                            models.err res, err
                        else
                            res.status 200
                            res.end JSON.stringify
                                    status: getOpenStatus()
                                    spotsTaken: count
                                    spotsRemaining: regularSpots - count
                , () ->
                    # non admins only get open-priority-closed
                    res.status 200
                    res.end JSON.stringify status: getOpenStatus()

    # PUT /openStatus
    app.route '/openStatus'
        .put auth.requireAdmin, (req, res) ->
            if req.body.status?
                setOpenStatus req.body.status, (err) ->
                    if err?
                        res.status 400
                        res.end err
                    else
                        res.status 200
                        res.end 'Status updated.'
            else
                res.status 400
                res.end 'Malformed request.'

    # POST /register
    app.route '/register'
        .post auth.requireLoggedIn, (req, res) ->
            console.log req.body
            # validate request
            clean = {}
            require = (key, next) ->
                if req.body[key]?
                    clean[key] = req.body[key]
                    next()
                else
                    res.status 400
                    res.send 'Malformed request.'
            require 'firstName', () ->
                require 'lastName', () ->
                    require 'email', () ->
                        console.log clean
                        if getOpenStatus() is 'closed'
                            res.status 400
                            res.send 'Malformed request.'
                            return

                        # we are open and they can register

                        # dietary restrictions
                        if req.body.foodRestriction?
                            clean.foodRestriction = req.body.foodRestriction

                        # @TODO: validator for non-CMU folks
                        validateCode = -> false

                        # check school stuff
                        if req.body.andrewID?
                            clean.andrewID = req.body.andrewID
                            clean.school = 'Carnegie Mellon University'
                        else if req.body.code? and validateCode req.body.code
                            clean.school = getSchool req.body.code
                        else
                            res.status 400
                            res.send 'Malformed request.'
                            return

                        models.User.findOne
                                userID: req.session.userID
                            , (err, user) ->
                                if err?
                                    models.err res, err
                                else
                                    if user?
                                        if user.isRegistered
                                            res.status 403
                                            res.send 'Cannot re-register.'
                                            return
                                        user.firstName = clean.firstName
                                        user.lastName = clean.lastName
                                        user.email = clean.email
                                        user.school = clean.school
                                        if clean.andrewID?
                                            user.andrewID = clean.andrewID
                                        user.isRegistered = true
                                        user.registrationTime = Date.now()
                                        user.save (err) ->
                                            if err?
                                                models.err res, err
                                            else
                                                spotsAvailable () ->
                                                        user.isAccepted = true
                                                        user.save (err) ->
                                                            if err?
                                                                models.err res, err
                                                            else
                                                                res.status 200
                                                                res.send 'Successfully registered.'
                                                    , (err) ->
                                                            if err?
                                                                models.err res, err
                                                            else
                                                                user.isAccepted = false
                                                                user.save (err) ->
                                                                    if err?
                                                                        models.err res, err
                                                                    else
                                                                        res.status 200
                                                                        res.send 'Successfully registered.'
                                    else
                                        res.status 404
                                        res.end 'User not found.'
