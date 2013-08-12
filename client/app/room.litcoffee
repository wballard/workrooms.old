Control a single Room, including video and chat, running peer to peer.

    room = require './rooms/room.litcoffee'

    angular
      .module('workrooms')
      .controller('Room', ['$scope', '$routeParams', ($scope, $routeParams) ->
        $scope.room = room($scope.sky, $routeParams.roomid)
          .on('localvideo', ->
            $scope.$apply())
          .on('remotevideo', ->
            $scope.$apply())
          .on('localState', ->
            $scope.$apply())
          .on('synch', ->
            $scope.$apply())
        $scope.sky.linkToAngular $scope.room.clientLinkPath, $scope, 'me'
        $scope.$on 'start.speaking', ->
          console.log 'hiii'
      ])
