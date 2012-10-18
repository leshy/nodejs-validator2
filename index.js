(function() {
  var Validator, async, defineValidator, helpers, typevalidator, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  _ = require('underscore');
  async = require('async');
  helpers = require('helpers');
  exports.Validator = Validator = (function() {
    function Validator(validate) {
      var val, _ref;
      this.validate = validate;
      switch ((_ref = this.validate) != null ? _ref.constructor : void 0) {
        case String:
          this.validate = this.functions[this.validate];
          break;
        case Number:
          val = this.validate;
          this.validate = function(data, callback) {
            return this.functions.is(val, data, callback);
          };
          break;
        case Object:
          val = this.validate;
          this.validate = function(data, callback) {
            return this.functions.children(val, data, callback);
          };
          break;
        case Validator:
          val = this.validate;
          this.validate = val.validate;
          if (val.child) {
            this.child = val.child;
          }
      }
    }
    Validator.prototype.feed = function(data, callback) {
      if (!this.validate) {
        return this.execChildren(data, callback);
      } else {
        return this.validate(data, __bind(function(err, data) {
          if (err) {
            return callback(err, data);
          } else {
            return this.execChildren(data, callback);
          }
        }, this));
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
    Validator.prototype.functions = {};
    return Validator;
  })();
  defineValidator = exports.defineValidator = function(name, f) {
    name = name.toLowerCase();
    Validator.prototype.functions[name] = f;
    return Validator.prototype[name] = function() {
      var args, wrapped;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      wrapped = function(data, callback) {
        return f.apply(this, args.concat([data, callback]));
      };
      if (!(this.validate != null)) {
        this.validate = wrapped;
      } else {
        this.addChild(new Validator(wrapped));
      }
      return this;
    };
  };
  _.map(require('./validate.js').Validate, function(lvf, name) {
    return defineValidator(name, function() {
      var args, callback, target, _i;
      args = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), target = arguments[_i++], callback = arguments[_i++];
      return helpers.throwToCallback(lvf)(target, _.first(args), function(err, data) {
        return callback(err, !(err != null) ? target : void 0);
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
  defineValidator("type", function() {
    var args, callback, data, _i;
    args = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), data = arguments[_i++], callback = arguments[_i++];
    return typevalidator(_.first(args), data, callback);
  });
  _.map([String, Number, Boolean, Function, Array], function(type) {
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
      return callback("wrong value, got '" + data + "' (" + (typeof data) + ") and expected '" + compare + "' (" + (typeof compare) + ")");
    }
  });
  defineValidator("default", function(defaultvalue, data, callback) {
    if (data != null) {
      return callback(void 0, data);
    } else {
      return callback(void 0, defaultvalue);
    }
  });
  defineValidator("children", function(children, data, callback) {
    return async.parallel(helpers.hashmap(children, function(validator, name) {
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
}).call(this);
