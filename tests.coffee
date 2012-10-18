
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
    new v.Validator().String().feed 3, (err,data) -> if not err? then test.fail else cnt++
    new v.Validator().String().feed "hi", (err,data) -> if err? then test.fail else cnt++
    test.equals cnt, 2
    test.done()

exports.chain = (test) ->
    cnt = 0
    new v.Validator().default('lala').String().feed undefined,
        (err,data) ->
            test.equals err, undefined, "got err: #{err}"
            test.equals data, 'lala', "got wrong data: '#{ data }', expected 'lala'"
            cnt++    
    
    if cnt != 1 then test.fail() else test.done()

exports.children = (test) ->
    cnt = 0
    new v.Validator().children({ bla: new v.Validator().String(), kkk: new v.Validator().String() }).feed( { bla: 'lala', kkk:'string2' }, (err,data) -> if not err? then cnt++ else test.fail() )
    new v.Validator().children({ bla: new v.Validator().String(), kkk: new v.Validator().String() }).feed( { bla: 'lala', kkk: 3 }, (err,data) -> if err? then cnt++ else test.fail() )
    test.equals cnt, 2
    test.done()
