This is the root most controller.


    angular.module('workrooms')
      .controller('Application', [ '$scope', ($scope) ->
        $scope.sky = variablesky.connect().traceOn()
      ])
