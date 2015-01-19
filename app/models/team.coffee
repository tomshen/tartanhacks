# @file team.coffee
# @brief Defines the Team database model.
# @author Oscar Bezi, oscar@bezi.io
# @since 7 January 2015
#===============================================================================

mongoose = require 'mongoose'
Schema = mongoose.Schema

TeamSchema = new Schema
    ownerID: String
    member2ID: String
    member3ID: String
    member4ID: String
    passphrase: String
    teamName: String
    teamAvatar: String
    isLooking:
        type: Boolean
        default: false
    location: String

    hackName: String
    hackUrl: String
    hackDescription: String
    isSubmitted:
        type: Boolean
        default: false

module.exports = mongoose.model 'Team', TeamSchema
