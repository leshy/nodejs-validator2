_ = require 'underscore'
async = require 'async'
helpers = require 'helpers'

exports.v = (args...) -> new exports.Validator(args)

exports.Validator = class Validator
  constructor: (@validate, @args=[], @child) ->
    if @validate?.constructor is Array then @args = @validate[1]; @child = @validate[2]; @validate = @validate[0]
    if @args?.constructor != Array then @args = [ @args ]
    
    switch @validate?.constructor
        when String
            if tmp = @functions[ @validate ] then @validate = tmp else @args = [ @validate ]; @validate = @functions.is
        when Number then @args = [ @validate ]; @validate = @functions.is
        when Object then @args = [ @validate ]; @validate = @functions.children
        when Validator then val = @validate; @validate = val.validate; @args = val.args; if val.child then @child = val.child
        when Boolean then @validate = @functions.exists; @args = []
    if @child?.constructor is Array then @child = new Validator(@child)
        
  name: -> helpers.find(@functions, (f,name) => if f is @validate then return name else return false )
  feed: (data,callback) -> if not @validate then @execChildren(data,callback) else @validate.apply(this, @args.concat([ data, (err,data) => if err then callback err,data else @execChildren(data,callback) ]))
  execChildren: (data,callback) -> if @child then @child.feed(data,callback) else callback undefined, data
  addChild: (child) -> if @child? then @child.addChild(child) else @child = child
  serialize: -> [ @name(), @serializeArgs(), if @child then @child.serialize() ]
  serializeArgs: -> return _.map( @args, (arg) -> helpers.unimap arg, (val) -> if val?.constructor is Validator then val.serialize(); else val);
  json: -> JSON.stringify @serialize()
  functions: {}

defineValidator = exports.defineValidator = (name,f) ->
    name = name.toLowerCase()
    Validator::functions[name] = f
    Validator::functions[helpers.capitalize(name)] = f
    Validator::[name] = Validator::[helpers.capitalize(name)] = (args...) ->
        if not @validate? then @validate = f; @args = args; else @addChild new Validator(f,args) 
        this

_.map require('./validate.js').Validate, (lvf,name) -> defineValidator name, (args,data,callback) -> helpers.throwToCallback(lvf) data, args, (err) -> callback(err, data if not err?)

typevalidator = (type,target,callback) -> if type is target?.constructor then callback undefined, target else callback "wrong type '#{ target?.constructor.name }', expected '#{ type.name }'"

defineValidator "type", (args,data,callback) -> typevalidator _.first(args), data, callback
_.map [ Object, String, Number, Boolean, Function, Array ], (type) -> defineValidator type.name, (args...,data,callback) -> typevalidator type, data, callback

defineValidator "set", (setto,data,callback) -> callback undefined, setto

defineValidator "is", (compare,data,callback) -> if data is compare then callback undefined, data else callback "wrong value, got #{ JSON.stringify(data) } (#{typeof data}) and expected #{ JSON.stringify(compare) } (#{typeof compare})"

defineValidator "default", (defaultvalue,data,callback) -> if data? then callback undefined,data else callback undefined, if defaultvalue.constructor is Function then defaultvalue() else defaultvalue

defineValidator "exists", (data,callback) -> if data? then callback undefined,data else callback "data doesn't exist"

defineValidator "instance", (data,callback) -> if typeof data is 'object' and data.constructor != Object then callback undefined, data else callback "#{ data } (#{typeof data}) is not an instance"

defineValidator "children", (children,data,callback) ->
    if not data then callback("I didn't get a dict");return
    async.parallel(helpers.hashmap( children, (validator, name) -> (callback) -> new Validator(validator).feed(data[name], callback)),
        (err,changeddata) -> if err? then callback(err) else callback undefined, _.extend(data,changeddata))

defineValidator "or", (validators...,data,callback) ->
    next = -> if not validators.length then callback('none of the validator passed') else (new Validator(validators.pop())).feed( data, (err,data) -> if not err? then callback(undefined,data) else next())
    next()

defineValidator "not", (child,data,callback) -> child = new Validator(child); child.feed data, (err,data) -> if not err? then callback("validator #{ child.name() } passed and it shouldn't have") else callback(undefined,data)

defineValidator "regex", (regex,data,callback) ->
    match = regex.exec(data)
    if match then callback undefined, match else callback "regex failed"