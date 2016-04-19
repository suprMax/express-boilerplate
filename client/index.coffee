React = require('react')
{ render } = require('react-dom')

Router = require('react-router/lib/Router')
browserHistory = require('react-router/lib/browserHistory')
match = require('react-router/lib/match')

{ syncHistoryWithStore } = require('react-router-redux')
{ Provider } = require('react-redux')

{ trigger } = require('redial')

require('es6-promise').polyfill()
require('fastclick')(document.body)

createStore = require('./store')
createRouter = require('./router')

isEmpty = (obj) -> JSON.stringify(obj) is '{}'

###
  Router setup. Accepts history and routes.
  Both history and routes are relying on store and dispatching events.
###
renderPage = (store, history, routes) ->
  Component =
    <Provider store={store}>
      <Router history={history} routes={routes} />
    </Provider>

  render(Component, document.getElementById('main'))

startRouter = (store, history) ->
  hasInitialData = not isEmpty(__appState__)
  routes = createRouter(store)

  handleFetch = (location) ->
    matchPage = (error, redirect, props) ->
      locals =
        location: props.location
        params: props.params
        dispatch: store.dispatch

      handleError = (error) ->
        console.error("Request #{location.pathname} failed to fetch data:", error)

      trigger('fetch', props.components, locals).catch(handleError) unless hasInitialData
      trigger('defer', props.components, locals).catch(handleError)
      hasInitialData = false

    match({ routes, location }, matchPage)

  # React router doesn't allow for a dynamic routing configuration.
  # Custom "dynamic" routing can be implemented:
  #   1. Unmount currently mounted router
  #   2. Mount new router with new routing configuration
  #
  # This leads to errors with active components being unmounted at wrong moments.
  renderPage(store, history, routes)
  history.listen(handleFetch) unless __appState__.error

###
  Call setup functions. First setup store, then initialize router.
###
store = createStore(__appState__)
history = syncHistoryWithStore(browserHistory, store)
startRouter(store, history)
