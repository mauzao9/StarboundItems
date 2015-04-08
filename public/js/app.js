var app = angular.module('starboundItems', []);

var App = Ember.Application.create({
  LOG_TRANSITIONS: true
});

App.Router.map(function () {
  this.route('all');
  this.route('stats');
});
