_ = require 'underscore'
async = require 'async'
helpers = require 'helpers'

exports.Validator = class Validator
  constructor: (@validate, @args=[], @child) ->
    if @validate?.constructor is Array then @args = @validate[1]; @child = @validate[2]; @validate = @validate[0]
    if @args?.constructor is not Array then @args = [ @args ]
        
    switch @validate?.constructor
        when String then @validate = @functions[ @validate ]
        when Number then @args = [ @validate ]; @validate = @functions.is
        when Object then @args = [ @validate ]; @validate = @functions.children; @args = [ val ]
        when Validator then val = @validate; @validate = val.validate; @args = val.args; if val.child then @child = val.child

    if @child?.constructor is Array then @child = new Validator(@child)
        
  name: -> helpers.find(@functions, (f,name) => if f is @validate then return name else return false )
  feed: (data,callback) -> if not @validate then @execChildren(data,callback) else @validate.apply(this, @args.concat([ data, (err,data) => if err then callback err,data else @execChildren(data,callback) ]))
  execChildren: (data,callback) -> if @child then @child.feed(data,callback) else callback undefined, data
  addChild: (child) -> if @child? then @child.addChild(child) else @child = child
  serialize: -> [ @name(), @args, if @child then @child.serialize() ]
  json: -> JSON.stringify @serialize()
  functions: {} 

defineValidator = exports.defineValidator = (name,f) ->
    name = name.toLowerCase()
    Validator.prototype.functions[name] = f
    Validator.prototype[name] = (args...) ->
        if not @validate? then @validate = f; @args = args; else @addChild new Validator(f,args) 
        this

_.map require('./validate.js').Validate, (lvf,name) -> defineValidator name, (args,target,callback) -> helpers.throwToCallback(lvf) target, _.first(args), (err,data) -> callback(err, target if not err?)

typevalidator = (type,target,callback) -> if type is target?.constructor then callback undefined, target else callback "wrong type '#{ target?.constructor.name }', expected '#{ type.name }'"
defineValidator "type", (args,data,callback) -> typevalidator _.first(args), data, callback
_.map [ String, Number, Boolean, Function, Array ], (type) -> defineValidator type.name, (args...,data,callback) -> typevalidator type, data, callback

defineValidator "set", (setto,data,callback) -> callback undefined, setto
defineValidator "is", (compare,data,callback) -> if data is compare then callback undefined, data else callback "wrong value, got #{ JSON.stringify(data) } (#{typeof data}) and expected #{ JSON.stringify(compare) } (#{typeof compare})"
defineValidator "default", (defaultvalue,data,callback) -> if data? then callback undefined,data else callback undefined,defaultvalue

defineValidator "children", (children,data,callback) ->
    async.parallel(helpers.hashmap( children, (validator, name) -> (callback) -> new Validator(validator).feed(data[name], callback)),
        (err,changeddata) -> if err? then callback(err) else callback undefined, _.extend(data,changeddata))



