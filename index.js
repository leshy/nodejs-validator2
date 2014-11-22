// Generated by CoffeeScript 1.7.1
(function() {
  var Validator, async, defineValidator, helpers, typevalidator, validableTypes, _,
    __slice = [].slice;

  _ = require('underscore');

  async = require('async');

  helpers = require('helpers');

  exports.v = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new exports.Validator(args);
  };

  exports.Validator = Validator = (function() {
    function Validator(validate, args, child) {
      var f, typeValidatorMatch, val, _ref, _ref1, _ref2, _ref3;
      this.validate = validate;
      this.args = args != null ? args : [];
      this.child = child;
      if (((_ref = this.validate) != null ? _ref.constructor : void 0) === Array) {
        this.args = this.validate[1];
        this.child = this.validate[2];
        this.validate = this.validate[0];
      }
      if (((_ref1 = this.args) != null ? _ref1.constructor : void 0) !== Array) {
        this.args = [this.args];
      }
      switch ((_ref2 = this.validate) != null ? _ref2.constructor : void 0) {
        case Function:
          if (typeValidatorMatch = _.find(validableTypes, (function(_this) {
            return function(t) {
              return t === _this.validate;
            };
          })(this))) {
            this.validate = this.functions[this.validate.name];
          }
          break;
        case String:
          if (f = this.functions[this.validate]) {
            this.validate = f;
          } else {
            this.args = [this.validate];
            this.validate = this.functions.is;
          }
          break;
        case Number:
          this.args = [this.validate];
          this.validate = this.functions.is;
          break;
        case Object:
          this.args = [this.validate];
          this.validate = this.functions.children;
          break;
        case Validator:
          val = this.validate;
          this.validate = val.validate;
          this.args = val.args;
          if (val.child) {
            this.child = val.child;
          }
          break;
        case Boolean:
          this.validate = this.functions.exists;
          this.args = [];
      }
      if (((_ref3 = this.child) != null ? _ref3.constructor : void 0) === Array) {
        this.child = new Validator(this.child);
      }
    }

    Validator.prototype.name = function() {
      return helpers.find(this.functions, (function(_this) {
        return function(f, name) {
          if (f === _this.validate) {
            return name;
          } else {
            return false;
          }
        };
      })(this));
    };

    Validator.prototype.feed = function(data, callback) {
      if (!this.validate) {
        return this.execChildren(data, callback);
      } else {
        return this.validate.apply(this, this.args.concat([
          data, (function(_this) {
            return function(err, data) {
              if (err) {
                return callback(err, data);
              } else {
                return _this.execChildren(data, callback);
              }
            };
          })(this)
        ]));
      }
    };

    Validator.prototype.execChildren = function(data, callback) {
      if (this.child) {
        return this.child.feed(data, callback);
      } else {
        return callback(void 0, data);
      }
    };

    Validator.prototype.addChild = function(child) {
      if (this.child != null) {
        return this.child.addChild(child);
      } else {
        return this.child = child;
      }
    };

    Validator.prototype.serialize = function() {
      if (this.child) {
        return [this.name(), this.serializeArgs(), this.child.serialize()];
      } else {
        return [this.name(), this.serializeArgs()];
      }
    };

    Validator.prototype.serializeArgs = function() {
      return _.map(this.args, function(arg) {
        return helpers.unimap(arg, function(val) {
          if ((val != null ? val.constructor : void 0) === Validator) {
            return val.serialize();
          } else {
            return val;
          }
        });
      });
    };

    Validator.prototype.json = function() {
      return JSON.stringify(this.serialize());
    };

    Validator.prototype.functions = {};

    return Validator;

  })();

  defineValidator = exports.defineValidator = function(name, f) {
    if (!name) {
      throw "defineValidator didn't get a name";
    }
    name = name.toLowerCase();
    Validator.prototype.functions[name] = f;
    Validator.prototype.functions[helpers.capitalize(name)] = f;
    return Validator.prototype[name] = Validator.prototype[helpers.capitalize(name)] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this.validate == null) {
        this.validate = f;
        this.args = args;
      } else {
        this.addChild(new Validator(f, args));
      }
      return this;
    };
  };

  _.map(require('./validate.js').Validate, function(lvf, name) {
    return defineValidator(name, function(args, data, callback) {
      return helpers.throwToCallback(lvf)(data, args, function(err) {
        return callback(err, err == null ? data : void 0);
      });
    });
  });

  typevalidator = function(type, target, callback) {
    if (type === (target != null ? target.constructor : void 0)) {
      return callback(void 0, target);
    } else {
      return callback("wrong type '" + (target != null ? target.constructor.name : void 0) + "', expected '" + type.name + "'");
    }
  };

  defineValidator("type", function(args, data, callback) {
    return typevalidator(_.first(args), data, callback);
  });

  validableTypes = [Object, String, Number, Boolean, Function, Array];

  _.map(validableTypes, function(type) {
    return defineValidator(type.name, function() {
      var args, callback, data, _i;
      args = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), data = arguments[_i++], callback = arguments[_i++];
      return typevalidator(type, data, callback);
    });
  });

  defineValidator("set", function(setto, data, callback) {
    return callback(void 0, setto);
  });

  defineValidator("is", function(compare, data, callback) {
    if (data === compare) {
      return callback(void 0, data);
    } else {
      return callback("wrong value, got " + data + " (" + (typeof data) + ") and expected " + (JSON.stringify(compare)) + " (" + (typeof compare) + ")");
    }
  });

  defineValidator("default", function(defaultvalue, data, callback) {
    if (data != null) {
      return callback(void 0, data);
    } else {
      return callback(void 0, defaultvalue.constructor === Function ? defaultvalue() : defaultvalue);
    }
  });

  defineValidator("exists", function(data, callback) {
    if (data != null) {
      return callback(void 0, data);
    } else {
      return callback("data doesn't exist");
    }
  });

  defineValidator("instance", function(data, callback) {
    if (typeof data === 'object' && data.constructor !== Object) {
      return callback(void 0, data);
    } else {
      return callback("" + data + " (" + (typeof data) + ") is not an instance");
    }
  });

  defineValidator("children", function(children, data, callback) {
    if (!data) {
      callback('undefined');
      return;
    }
    return async.parallel(helpers.dictMap(children, function(validator, name) {
      return function(callback) {
        return new Validator(validator).feed(data[name], callback);
      };
    }), function(err, changeddata) {
      if (err != null) {
        return callback(err);
      } else {
        return callback(void 0, _.extend(data, changeddata));
      }
    });
  });

  defineValidator("or", function() {
    var callback, data, next, validators, _i;
    validators = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), data = arguments[_i++], callback = arguments[_i++];
    next = function() {
      if (!validators.length) {
        return callback('none of the validator passed');
      } else {
        return (new Validator(validators.pop())).feed(data, function(err, data) {
          if (err == null) {
            return callback(void 0, data);
          } else {
            return next();
          }
        });
      }
    };
    return next();
  });

  defineValidator("not", function(child, data, callback) {
    child = new Validator(child);
    return child.feed(data, function(err, data) {
      if (err == null) {
        return callback("validator " + (child.name()) + " passed and it shouldn't have");
      } else {
        return callback(void 0, data);
      }
    });
  });

}).call(this);
