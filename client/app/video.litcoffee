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
            .before("<div class='background'></div>")
            .before("<div class='highlight'></div>")
            .before("<div class='muted'></div>")
            .before("<div class='user-icon'></div>")
          $highlight = $(element).parent().find('.highlight')
          $muted = $(element).parent().find('.muted')

          $highlight.hide()

Speaking events are handled here, as well as sent up the scope chain.

          $scope.$on 'start.speaking', ->
            $highlight.show()
          $scope.$on 'stop.speaking', ->
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

Shim in an output stream with gain control. Can you hear me now?

              if attrs.autoGain
                audioDestination = audioContext.createMediaStreamDestination()
                gainFilter = audioContext.createGain()
                audioSource.connect(gainFilter)
                gainFilter.connect(audioDestination)
                stream.removeTrack(stream.getAudioTracks()[0])
                stream.addTrack(audioDestination.stream.getAudioTracks()[0])

These are ex-recto.

              interval = 100
              meanThreshold = 18

Start up the monitoring loop.

              poller = () ->
                if element[0].src
                  setTimeout ->
                    audioAnalyser.getFloatFrequencyData(fftBins)
                    valid = _.select(fftBins, (x) -> x < 0)
                    maxVolume = _.max(valid)
                    meanVolume = _.reduce(valid, (sum, x) -> sum + x) / fftBins.length
                    if Math.abs(maxVolume - meanVolume) < meanThreshold
                      $scope.$emit('start.speaking') if not speaking
                      gainFilter.gain.value = 1.0 if gainFilter
                      speaking = true
                    else
                      $scope.$emit('stop.speaking') if speaking
                      gainFilter.gain.value = 0.2 if gainFilter
                      speaking = false
                    poller()
                  , interval
              poller()

Visual feedback.

              $scope.$watch "#{attrs.attachStream}.muteVideo", (muted) ->
                if muted
                  element.addClass 'muteVideo'
                else
                  element.removeClass 'muteVideo'
              $scope.$watch "#{attrs.attachStream}.muteAudio", (muted) ->
                if muted
                  $muted.show()
                else
                  $muted.hide()

And an unhook.

            else
              element[0].src = ""
      ])
      .directive('muteAudioStream', [ ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
          template = """
            <span class="icon-stack">
              <i class="icon-microphone"></i>
              <i class="icon-stack-base overlay"></i>
            </span>
            """
          $off = $(element).append(template).find('.overlay')
          monitoringStream = null
          showState = ->
            if monitoringStream
              if _.any(monitoringStream.getAudioTracks(), (x) -> x.enabled)
                $off.hide()
              else
                $off.show()
          $(element).on 'click', ->
            if monitoringStream
              _.each monitoringStream.getAudioTracks(), (x) ->
                x.enabled = $off.is(':visible')
              $scope.$apply ->
                ngModel.$setViewValue not $off.is(':visible')
              showState()
          $scope.$watch attrs.muteAudioStream, (stream) ->
            monitoringStream = stream
            showState()
      ])
      .directive('muteVideoStream', [ ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
          template = """
            <span class="icon-stack">
              <i class="icon-facetime-video"></i>
              <i class="icon-stack-base overlay"></i>
            </span>
            """
          $off = $(element).append(template).find('.overlay')
          monitoringStream = null
          showState = ->
            if monitoringStream
              if _.any(monitoringStream.getVideoTracks(), (x) -> x.enabled)
                $off.hide()
              else
                $off.show()
          $(element).on 'click', ->
            if monitoringStream
              _.each monitoringStream.getVideoTracks(), (x) ->
                x.enabled = $off.is(':visible')
              $scope.$apply ->
                ngModel.$setViewValue not $off.is(':visible')
              showState()
          $scope.$watch attrs.muteVideoStream, (stream) ->
            monitoringStream = stream
            showState()
      ])
