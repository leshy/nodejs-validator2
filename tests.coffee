
v = require './index.coffee'

exports.set = (test) ->
    cnt = 0
    new v.Validator().set('bla').feed 3, (err,data) -> if not data is 'bla' then test.fail else cnt++
    test.equals cnt, 1
    test.done()
    
exports.default = (test) ->
    cnt = 0
    new v.Validator().default('bla').feed undefined, (err,data) -> if not data is 'bla' then test.fail else cnt++
    new v.Validator().default('bla').feed 3, (err,data) -> if not data is 3 then test.fail else cnt++
    test.equals cnt, 2
    test.done()

exports.type = (test) ->
    cnt = 0
    new v.Validator().string().feed 3, (err,data) -> if not err? then test.fail "didn't fail on wrong type" else cnt++
    new v.Validator().string().feed "hi", (err,data) -> if err? then test.fail err else cnt++
    test.equals cnt, 2
    test.done()

exports.String = (test) ->
    testv = (v,callback) ->
        cnt = 0
        v.feed('bla',(err,data) -> if err? then test.fail() else cnt++)
        v.feed(3,(err,data) -> if not err? then test.fail() else cnt++)
        test.equals cnt, 2
        callback()        
    testv(new v.Validator("string"),-> testv(new v.Validator().string(), test.done))


exports.is = (test) ->
    cnt = 0
    new v.Validator().is(3).feed 3, (err,data) -> if err? then test.fail err else cnt++
    new v.Validator().is(3).feed "hi", (err,data) -> if not err? then test.fail "didn't fail on string" else cnt++
    test.equals cnt, 2
    test.done()


exports.StringIsShortcut = (test) ->
    cnt = 0
    new v.Validator("bla").feed "bla", (err,data) -> if err? then test.fail err else cnt++
    new v.Validator("bla").feed "blax", (err,data) -> if not err? then test.fail "didn't fail on wrong string" else cnt++
    test.equals cnt, 2
    test.done()



exports.chain = (test) ->
    cnt = 0
    new v.Validator().default('lala').string().feed undefined,
        (err,data) ->
            test.equals err, undefined, "got err: #{err}"
            test.equals data, 'lala', "got wrong data: '#{ data }', expected 'lala'"
            cnt++
            
    new v.Validator().default('lala').string().feed "FLALA",
        (err,data) ->
            test.equals err, undefined, "got err: #{err}"
            test.equals data, 'FLALA', "got wrong data: '#{ data }', expected 'lala'"
            cnt++

        
    if cnt != 2 then test.fail('wrong cnt') else test.done()

exports.empty = (test) ->
    new v.Validator().feed "BLABLA", (err,data) -> if not err? then test.done() else test.fail()

exports.children = (test) ->
    cnt = 0
    new v.Validator().children({ bla: new v.Validator().string(), kkk: new v.Validator().string() }).feed( { bla: 'lala', kkk:'string2' }, (err,data) -> if not err? then cnt++ else test.fail('1') )
    new v.Validator().children({ bla: new v.Validator('string'), kkk: new v.Validator().string() }).feed( { bla: 'lala', kkk: 3 }, (err,data) -> if err? then cnt++ else test.fail('should have failed!') )
    test.equals cnt, 2
    test.done()


exports.stringInit = (test) ->
    x = new v.Validator('string')
    cnt = 0
    x.feed('bla',(err,data) -> if not err? then cnt++ else test.fail(err))
    x.feed(3,(err,data) -> if err? then cnt++ else test.fail('didnt fail'))
    test.equals cnt, 2
    test.done()

    
exports.isNumInit = (test) ->
    x = new v.Validator(3)
    cnt = 0
    x.feed('bla',(err,data) -> if err? then cnt++ else test.fail "string passed" )
    x.feed(3,(err,data) -> if not err? then cnt++ else test.fail err )
    test.equals cnt, 2
    test.done()
    
exports.NoChild = (test) ->
    x = new v.Validator()
    test.equals x.validate, undefined, "my validate exists!"
    test.equals x.child, undefined, "my child exists!"
    x.string()
    test.equals x.child, undefined, "my child exists!"
    test.notEqual x.validate, undefined, "my validator doesn't exist!"
    cnt = 0
    x.feed "blaasfasf", (err,data) -> if err? then test.fail() else cnt++
    test.equals cnt, 1
    test.done()

exports.ChildrenInit = (test) ->
    cnt = 0
    x = new v.Validator({bla : "string", a: "array"})
    x.feed( {bla: "prdac", a: [ 1, 3 ,4 ] }, (err,data) -> if not err? then cnt++ else test.fail())
    x.feed( {bla: "prdac", a: 3 }, (err,data) -> if err? then cnt++ else test.fail('I should have failed'))
    test.done()

exports.Name = (test) ->
    x = new v.Validator('string')
    test.equals x.name(), 'string'
    test.done()

exports.Serialize = (test) ->
    x = new v.Validator('default', 3).number()
    serialized = x.serialize()
    y = new v.Validator(serialized)
    test.deepEqual serialized, [ 'default', [ 3 ], [ 'number', [] ] ]
    test.deepEqual y.serialize(), serialized
    test.done()

exports.complexSerialize = (test) ->
    x = new v.Validator().default({ bla: 3, bla2: "kkk"}).Children({ bla: 3, bla2: new v.Validator('default', 'bla').string()})
    serialized = x.serialize()
    y = new v.Validator(serialized)
    test.deepEqual(y.serialize(),serialized)
    test.done()

exports.not = (test) ->
    x = new v.Validator().not(new v.Validator('string'))
    cnt = 0
    x.feed('bla', (err,data) -> if not err? then test.fail('string passed') else cnt++)
    x.feed(3, (err,data) -> if err? then test.fail('number didnt pass') else cnt++)
    test.equal(cnt,2)
    test.done()


exports.livevalidation = (test) ->
    x = new v.Validator().Default(6666666).Length({maximum: 20, minimum: 5})
    cnt = 0
    x.feed undefined,(err,data) -> if not err? then cnt++ else test.fail("a valid thing failed")
    x.feed 3,(err,data) -> if err? then cnt++ else test.fail("an invalid thing passed")
    test.equal(cnt,2)
    test.done()


exports.exists = (test) ->
    x = new v.Validator().Exists()
    cnt = 0
    x.feed 3,(err,data) -> if not err? then cnt++ else test.fail("a valid thing failed")
    x.feed undefined,(err,data) -> if err? then cnt++ else test.fail("an invalid thing passed")
    test.equal(cnt,2)
    test.done()

exports.existsShortcut = (test) ->
    x = new v.Validator(true)
    cnt = 0
    x.feed 3,(err,data) -> if not err? then cnt++ else test.fail("a valid thing failed")
    x.feed undefined,(err,data) -> if err? then cnt++ else test.fail("an invalid thing passed")
    test.equal(cnt,2)
    test.done()


exports.defaultfun = (test) ->
    x = new v.Validator().Default( -> "BLA").Length({maximum: 10, minimum: 2})
    x.feed undefined,(err,data) -> test.equals "BLA", data
    test.done()


exports.or = (test) ->
    x = new v.Validator().or( 'string', 'object' )
    cnt = 0
    x.feed 'bla',(err,data) -> if err? then test.fail() else cnt++
    x.feed { bla: 3 },(err,data) -> if err? then test.fail() else cnt++
    x.feed true ,(err,data) -> if not err? then test.fail() else cnt++
    test.equals cnt, 3
    test.done()

