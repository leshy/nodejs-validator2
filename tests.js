(function() {
  var v;
  v = require('./index.coffee');
  exports.set = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator().set('bla').feed(3, function(err, data) {
      if (!data === 'bla') {
        return test.fail;
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 1);
    return test.done();
  };
  exports["default"] = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator()["default"]('bla').feed(void 0, function(err, data) {
      if (!data === 'bla') {
        return test.fail;
      } else {
        return cnt++;
      }
    });
    new v.Validator()["default"]('bla').feed(3, function(err, data) {
      if (!data === 3) {
        return test.fail;
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.type = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator().string().feed(3, function(err, data) {
      if (!(err != null)) {
        return test.fail("didn't fail on wrong type");
      } else {
        return cnt++;
      }
    });
    new v.Validator().string().feed("hi", function(err, data) {
      if (err != null) {
        return test.fail(err);
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.String = function(test) {
    var testv;
    testv = function(v, callback) {
      var cnt;
      cnt = 0;
      v.feed('bla', function(err, data) {
        if (err != null) {
          return test.fail();
        } else {
          return cnt++;
        }
      });
      v.feed(3, function(err, data) {
        if (!(err != null)) {
          return test.fail();
        } else {
          return cnt++;
        }
      });
      test.equals(cnt, 2);
      return callback();
    };
    return testv(new v.Validator("string"), function() {
      return testv(new v.Validator().string(), test.done);
    });
  };
  exports.is = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator().is(3).feed(3, function(err, data) {
      if (err != null) {
        return test.fail(err);
      } else {
        return cnt++;
      }
    });
    new v.Validator().is(3).feed("hi", function(err, data) {
      if (!(err != null)) {
        return test.fail("didn't fail on string");
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.StringIsShortcut = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator("bla").feed("bla", function(err, data) {
      if (err != null) {
        return test.fail(err);
      } else {
        return cnt++;
      }
    });
    new v.Validator("bla").feed("blax", function(err, data) {
      if (!(err != null)) {
        return test.fail("didn't fail on wrong string");
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.chain = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator()["default"]('lala').string().feed(void 0, function(err, data) {
      test.equals(err, void 0, "got err: " + err);
      test.equals(data, 'lala', "got wrong data: '" + data + "', expected 'lala'");
      return cnt++;
    });
    new v.Validator()["default"]('lala').string().feed("FLALA", function(err, data) {
      test.equals(err, void 0, "got err: " + err);
      test.equals(data, 'FLALA', "got wrong data: '" + data + "', expected 'lala'");
      return cnt++;
    });
    if (cnt !== 2) {
      return test.fail('wrong cnt');
    } else {
      return test.done();
    }
  };
  exports.empty = function(test) {
    return new v.Validator().feed("BLABLA", function(err, data) {
      if (!(err != null)) {
        return test.done();
      } else {
        return test.fail();
      }
    });
  };
  exports.children = function(test) {
    var cnt;
    cnt = 0;
    new v.Validator().children({
      bla: new v.Validator().string(),
      kkk: new v.Validator().string()
    }).feed({
      bla: 'lala',
      kkk: 'string2'
    }, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail('1');
      }
    });
    new v.Validator().children({
      bla: new v.Validator('string'),
      kkk: new v.Validator().string()
    }).feed({
      bla: 'lala',
      kkk: 3
    }, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail('should have failed!');
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.stringInit = function(test) {
    var cnt, x;
    x = new v.Validator('string');
    cnt = 0;
    x.feed('bla', function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail(err);
      }
    });
    x.feed(3, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail('didnt fail');
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.isNumInit = function(test) {
    var cnt, x;
    x = new v.Validator(3);
    cnt = 0;
    x.feed('bla', function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail("string passed");
      }
    });
    x.feed(3, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail(err);
      }
    });
    test.equals(cnt, 2);
    return test.done();
  };
  exports.NoChild = function(test) {
    var cnt, x;
    x = new v.Validator();
    test.equals(x.validate, void 0, "my validate exists!");
    test.equals(x.child, void 0, "my child exists!");
    x.string();
    test.equals(x.child, void 0, "my child exists!");
    test.notEqual(x.validate, void 0, "my validator doesn't exist!");
    cnt = 0;
    x.feed("blaasfasf", function(err, data) {
      if (err != null) {
        return test.fail();
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 1);
    return test.done();
  };
  exports.ChildrenInit = function(test) {
    var cnt, x;
    cnt = 0;
    x = new v.Validator({
      bla: "string",
      a: "array"
    });
    x.feed({
      bla: "prdac",
      a: [1, 3, 4]
    }, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail();
      }
    });
    x.feed({
      bla: "prdac",
      a: 3
    }, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail('I should have failed');
      }
    });
    return test.done();
  };
  exports.Name = function(test) {
    var x;
    x = new v.Validator('string');
    test.equals(x.name(), 'string');
    return test.done();
  };
  exports.Serialize = function(test) {
    var serialized, x, y;
    x = new v.Validator('default', 3).number();
    serialized = x.serialize();
    y = new v.Validator(serialized);
    test.deepEqual(serialized, ['default', [3], ['number', [], void 0]]);
    test.deepEqual(y.serialize(), serialized);
    return test.done();
  };
  exports.complexSerialize = function(test) {
    var serialized, x, y;
    x = new v.Validator()["default"]({
      bla: 3,
      bla2: "kkk"
    }).Children({
      bla: 3,
      bla2: new v.Validator('default', 'bla').string()
    });
    serialized = x.serialize();
    y = new v.Validator(serialized);
    test.deepEqual(y.serialize(), serialized);
    return test.done();
  };
  exports.not = function(test) {
    var cnt, x;
    x = new v.Validator().not(new v.Validator('string'));
    cnt = 0;
    x.feed('bla', function(err, data) {
      if (!(err != null)) {
        return test.fail('string passed');
      } else {
        return cnt++;
      }
    });
    x.feed(3, function(err, data) {
      if (err != null) {
        return test.fail('number didnt pass');
      } else {
        return cnt++;
      }
    });
    test.equal(cnt, 2);
    return test.done();
  };
  exports.livevalidation = function(test) {
    var cnt, x;
    x = new v.Validator().Default(6666666).Length({
      maximum: 20,
      minimum: 5
    });
    cnt = 0;
    x.feed(void 0, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail("a valid thing failed");
      }
    });
    x.feed(3, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail("an invalid thing passed");
      }
    });
    test.equal(cnt, 2);
    return test.done();
  };
  exports.exists = function(test) {
    var cnt, x;
    x = new v.Validator().Exists();
    cnt = 0;
    x.feed(3, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail("a valid thing failed");
      }
    });
    x.feed(void 0, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail("an invalid thing passed");
      }
    });
    test.equal(cnt, 2);
    return test.done();
  };
  exports.existsShortcut = function(test) {
    var cnt, x;
    x = new v.Validator(true);
    cnt = 0;
    x.feed(3, function(err, data) {
      if (!(err != null)) {
        return cnt++;
      } else {
        return test.fail("a valid thing failed");
      }
    });
    x.feed(void 0, function(err, data) {
      if (err != null) {
        return cnt++;
      } else {
        return test.fail("an invalid thing passed");
      }
    });
    test.equal(cnt, 2);
    return test.done();
  };
  exports.defaultfun = function(test) {
    var x;
    x = new v.Validator().Default(function() {
      return "BLA";
    }).Length({
      maximum: 10,
      minimum: 2
    });
    x.feed(void 0, function(err, data) {
      return test.equals("BLA", data);
    });
    return test.done();
  };
  exports.or = function(test) {
    var cnt, x;
    x = new v.Validator().or('string', 'object');
    cnt = 0;
    x.feed('bla', function(err, data) {
      if (err != null) {
        return test.fail();
      } else {
        return cnt++;
      }
    });
    x.feed({
      bla: 3
    }, function(err, data) {
      if (err != null) {
        return test.fail();
      } else {
        return cnt++;
      }
    });
    x.feed(true, function(err, data) {
      if (!(err != null)) {
        return test.fail();
      } else {
        return cnt++;
      }
    });
    test.equals(cnt, 3);
    return test.done();
  };
}).call(this);
