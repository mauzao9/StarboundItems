var App = Ember.Application.create({
  LOG_TRANSITIONS: true
});

App.Router.map(function () {
  this.route('all');
  this.route('search', function () {
    this.route('results', { path: ':criteria' });
  });
  this.route('stats');
});

// redirect from '/' to '/search' route.
App.IndexRoute = Ember.Route.extend({
  beforeModel: function () {
    this.transitionTo('search');
  }
});

App.SearchController = Ember.Controller.extend({
  searchText: '',

  onSearchTextChange: function () {
    Ember.run.debounce(this, function () {
      this.send('updateSearch', this.get('searchText'));
    }, 1000);

  }.observes('searchText'),

  actions: {
    updateSearch: function (searchText) {
      this.transitionToRoute('search.results', searchText);
    },
  }
});

App.SearchResultsRoute = Ember.Route.extend({
  model: function (params) {
    var minimumLength = 2;

    if (params.criteria && params.criteria.length >= minimumLength) {
      return Ember.$.getJSON('/api/search?query=' + params.criteria);
    } else {
      this.transitionTo('search');
    }
  }
});

App.SearchResultsController = Ember.ArrayController.extend({
  resultCount: Ember.computed.alias('length')
});

App.ItemController = Ember.ObjectController.extend({
  // These kind of feel like hacks to me, but they do provide the extra
  // information needed to property render the view.
  // TODO: research best practices for this sort of thing.
  iconUrl: function () {
    return '/images/' + this.get('inventoryIcon');
  }.property('inventoryIcon'),

  rarityClass: function () {
    return this.get('rarity') && this.get('rarity').toLowerCase();
  }.property('rarity')
});

App.StatsRoute = Ember.Route.extend({
  model: function (params) {
    return Ember.$.getJSON('/api/stats');
  }
});

App.StatsController = Ember.ObjectController.extend({
  searchTerms: function () {
    var terms = this.get('search_terms');

    if (terms.length > 0) {
      // Note: the server performs the sort, so the first item will be the top score.
      terms[0].isTop = true;
    }

    return terms;
  }.property('model.search_terms')
});
