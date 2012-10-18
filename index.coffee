_ = require 'underscore'
async = require 'async'
helpers = require 'helpers'

exports.Validator = class Validator
  constructor: (@validate) ->
    switch @validate?.constructor
        when String then @validate = @functions[@validate]
        when Number then val = @validate; @validate = (data,callback) -> @functions.is val, data, callback
        when Object then val = @validate; @validate = (data,callback) -> @functions.children val, data, callback
        when Validator then val = @validate; @validate = val.validate; if val.child then @child = val.child
        
  feed: (data,callback) -> if not @validate then @execChildren(data,callback) else @validate data, (err,data) => if err then callback err,data else @execChildren(data,callback)
  execChildren: (data,callback) -> if @child then @child.feed(data,callback) else callback undefined, data
  addChild: (child) -> if @child? then @child.addChild(child) else @child = child
  functions: {}

defineValidator = exports.defineValidator = (name,f) ->
    name = name.toLowerCase()
    Validator.prototype.functions[name] = f
    Validator.prototype[name] = (args...) ->
        wrapped = (data,callback) -> f.apply(this,args.concat [data,callback])
        if not @validate? then @validate = wrapped else @addChild new Validator wrapped
        this

_.map require('./validate.js').Validate, (lvf,name) -> defineValidator name, (args...,target,callback) -> helpers.throwToCallback(lvf) target, _.first(args), (err,data) -> callback(err, target if not err?)

typevalidator = (type,target,callback) -> if type is target?.constructor then callback undefined, target else callback "wrong type '#{ target?.constructor.name }', expected '#{ type.name }'"
defineValidator "type", (args...,data,callback) -> typevalidator _.first(args), data, callback
_.map [ String, Number, Boolean, Function, Array ], (type) -> defineValidator type.name, (args...,data,callback) -> typevalidator type, data, callback

defineValidator "set", (setto,data,callback) -> callback undefined, setto
defineValidator "is", (compare,data,callback) -> if data is compare then callback undefined, data else callback "wrong value, got '#{ data }' (#{typeof data}) and expected '#{ compare }' (#{typeof compare})"
defineValidator "default", (defaultvalue,data,callback) -> if data? then callback undefined,data else callback undefined,defaultvalue

defineValidator "children", (children,data,callback) ->
    async.parallel(
        helpers.hashmap( children, (validator, name) -> (callback) -> new Validator(validator).feed(data[name], callback)),
        (err,changeddata) -> if err? then callback(err) else callback undefined, _.extend(data,changeddata))
