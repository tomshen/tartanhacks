# @file user.coffee
# @brief Defines the User database model.
# @author Oscar Bezi, oscar@bezi.io
# @since 7 January 2015
#===============================================================================

mongoose = require 'mongoose'
Schema = mongoose.Schema

UserSchema = new Schema
    userID:
        type: String
        required: true
        index:
            unique: true
    isAdmin:
        type: Boolean
        default: false

    isMentor:
        type: Boolean
        default: false

    isCheckedIn:
        type: Boolean
        default: false

    isRegistered:
        type: Boolean
        default: false

    registrationTime: Date
    isAccepted:
        type: Boolean
        default: false

    andrewID: String
    firstName: String
    lastName: String
    email: String
    resumeLink: String
    github: String
    avatarLink: String
    url: String
    pastHackathons: String
    linkedIn: String
    age: Number
    gender: String
    major: String
    school: String
    year: String
    foodRestriction: String

module.exports = mongoose.model 'User', UserSchema
