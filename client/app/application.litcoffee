This is the root most controller.

    store = require('store')

    angular.module('workrooms')
      .controller('Application', [ '$scope', ($scope) ->
        $scope.sky = variablesky.connect()
        if client = store.get('client')
          $scope.sky.client = client
        else
          store.set('client', $scope.sky.client)
      ])
