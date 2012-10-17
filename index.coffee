Validate = require('./validate.js').Validate
_ = require 'underscore'
colors = require 'colors'
helpers = require 'helpers'
async = require 'async'
Backbone = require 'backbone4000'

class Validator
  constructor: (@children...) -> true
    
  feed: (data) -> true
    
