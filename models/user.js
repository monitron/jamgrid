(function() {
  var Schema, User, UserSchema, mongoose, mongooseAuth;
  mongoose = require('mongoose');
  Schema = mongoose.Schema;
  mongooseAuth = require('mongoose-auth');
  UserSchema = new Schema({});
  User = null;
  UserSchema.plugin(mongooseAuth, {
    everymodule: {
      everyauth: {
        User: function() {
          return User;
        }
      }
    },
    password: {
      loginWith: 'login',
      extraParams: {
        email: String
      },
      everyauth: {
        getLoginPath: '/login',
        postLoginPath: '/login',
        loginView: 'login',
        getRegisterPath: '/register',
        postRegisterPath: '/register',
        registerView: 'register',
        loginSuccessRedirect: '/',
        registerSuccessRedirect: '/'
      }
    }
  });
  User = mongoose.model('User', UserSchema);
  module.exports = User;
}).call(this);
