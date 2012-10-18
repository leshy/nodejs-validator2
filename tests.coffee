
v = require './index.js'

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
    x.feed('bla',(err,data) -> if not err? then cnt++ else test.fail())
    x.feed(3,(err,data) -> if err? then cnt++ else test.fail())
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
    test.equals x.validate, undefined
    test.equals x.child, undefined
    x.string()
    test.equals x.child, undefined
    test.notEqual x.validate, undefined
    cnt = 0
    x.feed "blaasfasf", (err,data) -> if err? then test.fail() else cnt++
    test.equals cnt, 1
    test.done()

exports.ChildrenInit = (test) ->
    cnt = 0
    x = new v.Validator({bla : "string", a: "array"})
    x.feed( {bla: "prdac", a: [ 1, 3 ,4 ] }, (err,data) -> if not err? then cnt++ else test.fail())
    test.done()

    