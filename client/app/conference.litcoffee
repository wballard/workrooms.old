Conference service, this hooks up communications channels and media.

    getUserMedia = require('getusermedia')
    attachMediaStream = require('attachmediastream')
    WebRTC = require('webrtc')

    angular
        .module('workrooms')
        .service('conference', ->
            webrtc = new WebRTC(log: true)
            start: ->
                webrtc.startLocalMedia(
                    audio: true
                    video:
                        mandatory:
                            maxWidth: 320
                            maxHeight: 240
                    ,(err, stream) ->
                        if err
                            console.log err
                        else
                            console.log stream
                            attachMediaStream(stream, $('#videoOfMe')[0],
                                autoplay: true
                                mirror: true
                                muted: true
                            )
                )
        )
