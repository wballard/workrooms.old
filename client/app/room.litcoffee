Control a single Room, including video and chat, running peer to peer.

    room = require './rooms/room.litcoffee'

    angular
      .module('workrooms')
      .controller('Room', ['$scope', '$routeParams', ($scope, $routeParams) ->
        $scope.room = room($scope.sky, $routeParams.roomid)
        $scope.room.on 'localState', ->
            $scope.$apply()
        $scope.room.on 'synch', (localVideo, remoteVideo) ->
            $scope.$apply ->
              $scope.localVideo = localVideo
              $scope.remoteVideo = remoteVideo
        $scope.sky
          .linkToAngular($scope.room.clientLinkPath, $scope, 'me')
          .autoRemove()
      ])
