This is the root most controller.


    angular.module('workrooms')
      .controller('Application', [ '$scope', ($scope) ->
        console.log 'main app'
      ])
