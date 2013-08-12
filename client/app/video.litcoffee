Deal with video streams.

    attachMediaStream = require('attachmediastream')
    _ = require('lodash')

This is the really simple case of just hooking a stream on to an
`<video>` element.

    angular.module('gadgets')
      .directive('attachStream', [ ->
        restrict: 'A'
        link: ($scope, element, attrs) ->

Little bits of state.

          speaking = false
          $highlight = null

The basics, video tile wrapped with a background and highlight, which is
hidden/enabled based on detecting speaking.

          $(element)
            .wrap("<div class='background'></div>")
            .before("<div class='highlight'></div>")
            .before("<div class='user-icon'></div>")
          $highlight = $(element).parent().find('.highlight')

          $highlight.hide()

Speaking events are handled here, as well as sent up the scope chain.

          $scope.$on 'start.speaking', ->
            console.log 'start'
            $highlight.show()
          $scope.$on 'stop.speaking', ->
            console.log 'stop'
            $highlight.hide()


Hook to the video element and start things up.

          $scope.$watch attrs.attachStream, (stream) ->
            if stream
              attachMediaStream(stream, element[0])

Audio transform, fires off 'start.speaking' and 'stop.speaking'. This is the
basis of activity detection and automatic gain control to help combat feedback.
This whole idea is borrowed from [hark](https://npmjs.org/package/hark).

              audioContext = new webkitAudioContext()
              #rock the UK spelling
              audioAnalyser = audioContext.createAnalyser()
              audioAnalyser.fftSize = 512
              audioAnalyser.smoothingTimeConstant = 0.5
              fftBins = new Float32Array(audioAnalyser.fftSize)
              audioSource = audioContext.createMediaStreamSource(stream)
              audioSource.connect(audioAnalyser)
              interval = 100
              maxThreshold = -65
              meanThreshold = -97
              poller = () ->
                if element[0].src
                  setTimeout ->
                    audioAnalyser.getFloatFrequencyData(fftBins)
                    valid = _.select(fftBins, (x) -> x < 0)
                    maxVolume = _.max(valid)
                    meanVolume = _.reduce(valid, (sum, x) -> sum + x) / valid.length
                    if maxVolume > maxThreshold and meanVolume > meanThreshold
                      $scope.$emit('start.speaking') if not speaking
                      speaking = true
                    else
                      $scope.$emit('stop.speaking') if speaking
                      speaking = false
                    poller()
                  , interval
              poller()


And an unhook.

            else
              element[0].src = ""
      ])
