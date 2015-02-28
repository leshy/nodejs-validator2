# I'd like a blocking mode to exist, with limited subset of blocking-able validators
# (for module init validation, module accessors, and such simple local stuff [ look at validator2-extras ])
_ = require 'underscore'
async = require 'async'
helpers = require 'helpers'

exports.v = (args...) -> new Validator(args)

exports.Validator = class Validator
  constructor: (@validate, @args=[], @child) ->
    if @validate?.constructor is Array then @args = @validate[1]; @child = @validate[2]; @validate = @validate[0] # parsing of serialized validator
    if @args?.constructor != Array then @args = [ @args ]
    
    switch @validate?.constructor
        when Function then if typeValidatorMatch = _.find(validableTypes, (t) => t == @validate) then @validate = @functions[@validate.name] # can receive a type constructor, will type validate
        when String
            if f = @functions[ @validate ] then @validate = f
            else @args = [ @validate ]; @validate = @functions.is
        when Number then @args = [ @validate ]; @validate = @functions.is
        when Object then @args = [ @validate ]; @validate = @functions.children
        when Validator then val = @validate; @validate = val.validate; @args = val.args; if val.child then @child = val.child
        when Boolean
            if @validate is true then @validate = @functions.exists; @args = []
            if @validate is false then @validate = @functions.notexists; @args = []                
    if @child?.constructor is Array then @child = new Validator(@child)
        
  name: -> helpers.find(@functions, (f,name) => if f is @validate then return name else return false )
  feed: (data,callback) -> if not @validate?.apply? then @execChildren(data,callback) else @validate.apply(this, @args.concat([ data, (err,data) => if err then callback err,data else @execChildren(data,callback) ]))
  execChildren: (data,callback) -> if @child then @child.feed(data,callback) else callback undefined, data
  addChild: (child) -> if @child? then @child.addChild(child) else @child = child
  serialize: -> if @child then [ @name(), @serializeArgs(), @child.serialize() ] else [ @name(), @serializeArgs() ]
  serializeArgs: -> return _.map( @args, (arg) -> helpers.unimap arg, (val) -> if val?.constructor is Validator then val.serialize(); else val);
  json: -> JSON.stringify @serialize()
  functions: {}

defineValidator = exports.defineValidator = (name,f) ->
    if not name then throw "defineValidator didn't get a name"
    name = name.toLowerCase()
    Validator::functions[name] = f
    Validator::functions[helpers.capitalize(name)] = f
    Validator::[name] = Validator::[helpers.capitalize(name)] = (args...) ->
        if not @validate? then @validate = f; @args = args; else @addChild new Validator(f,args) 
        this

_.map require('./validate.js').Validate, (lvf,name) ->
    defineValidator name,
        (args,data,callback) ->
            if not callback
                callback = data
                data = args
                args = {}                
            helpers.throwToCallback(lvf) data, args, (err) ->
                callback(err, data if not err?)

typeValidator = (type,target,callback) -> if type is target?.constructor then callback undefined, target else callback "wrong type '#{ target?.constructor.name }', expected '#{ type.name }'"

defineValidator "type", (args,data,callback) -> typeValidator _.first(args), data, callback

validableTypes = [ Object, String, Number, Boolean, Function, Array ]
_.map validableTypes, (type) -> defineValidator type.name, (args...,data,callback) -> typeValidator type, data, callback

defineValidator "set", (setto,data,callback) -> callback undefined, setto

defineValidator "is", (compare,data,callback) -> if data is compare then callback undefined, data else callback "wrong value, got #{ data } (#{typeof data}) and expected #{ JSON.stringify(compare) } (#{typeof compare})"

defineValidator "default", (defaultvalue,data,callback) -> if data? then callback undefined,data else callback undefined, if defaultvalue.constructor is Function then defaultvalue() else defaultvalue

defineValidator "exists", (data,callback) -> if data? then callback undefined,data else callback "data doesn't exist"

defineValidator "notexists", (data,callback) -> if data? then callback "exists" else callback undefined, data

defineValidator "instance", (data,callback) -> if typeof data is 'object' and data.constructor != Object then callback undefined, data else callback "#{ data } (#{typeof data}) is not an instance"

defineValidator "optional", (validator,data,callback) -> if not data then callback() else new Validator(validator).feed(data, callback)

defineValidator "array", (array, data, callback) ->
    if data.constructor is Function and not callback then return typeValidator(Array,array,data)
    if not data.constructor is Array then return callback "#{ data } (#{typeof data}) is not an array"
    if array.length is 0 and data.length isnt 0 then return callback "expected empty array, got #{ data }"
    async.series _.map(array, ((validator,index) ->
        (callback) -> 
            new Validator(validator).feed data[index], callback)),
    (err,data) ->
        if err = _.last(err) then return callback err
        callback null, data
        
defineValidator "children", (children,data,callback) ->
    #console.log("children".red, children,"data".red, data,"callback".red,callback)
    if not data then callback('undefined'); return
    async.parallel(helpers.dictMap( children, (validator, name) -> (callback) -> new Validator(validator).feed(data[name], callback)),
        (err,changeddata) -> if err? then callback(err) else callback undefined, _.extend(data,changeddata))

defineValidator "or", (validators...,data,callback) ->
    next = -> if not validators.length then callback('none of the validator passed') else (new Validator(validators.pop())).feed( data, (err,data) -> if not err? then callback(undefined,data) else next())
    next()

defineValidator "not", (child,data,callback) -> child = new Validator(child); child.feed data, (err,data) -> if not err? then callback("validator #{ child.name() } passed and it shouldn't have") else callback(undefined,data)
