Deal with video streams.

    attachMediaStream = require('attachmediastream')

This is the really simple case of just hooking a stream on to an
`<video>` element.

    angular.module('gadgets')
      .directive('attachStream', [ ->
        restrict: 'A'
        link: ($scope, element, attrs) ->
          $(element)
            .wrap("<div class='highlight'></div>")
            .wrap("<div class='background'></div>")
            .before("<div class='user-icon'></div>")
          $scope.$watch attrs.attachStream, (stream) ->
            if stream
              attachMediaStream(stream, element[0])
            else
              element.src = ""
      ])
