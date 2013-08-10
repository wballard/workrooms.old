This is the main entry point, you create a room in VariableSky, which just
springs into existence if needed. Rooms track all the attached clients.

    EventEmitter = require('eventemitter2').EventEmitter2
    datachannel = require('./datachannel.litcoffee')
    _ = require('lodash')
    es = require('event-stream')
    tap = require('tap-stream')

So... many... settings... WebRTC defaults here to get audio, video, and
data.

    DEFAULT_OPTIONS =
      peerConfig:
        iceServers: [ {url: "stun:stun.l.google.com:19302"} ]
      peerConstraints:
        mandatory:
          OfferToReceiveAudio: true
          OfferToReceiveVideo: true
        optional: [ {RtpDataChannels: true} ]
      mediaConstraints:
        audio: true
        video:
            mandatory:
                maxWidth: 320
                maxHeight: 240

    class Room extends EventEmitter
      constructor: (skyclient, name, options) ->
        @name = name
        @client = skyclient.client
        options = _.extend({}, DEFAULT_OPTIONS, options)
        options.client = options.client or skyclient.client

Data channel for peer-peer communication.

        @dataChannel = dataChannel = datachannel(options)
        dataChannel.pipe(
          es.pipeline(
            #tap(0),
            es.mapSync( (data) =>
              if data.localvideo
                @localVideoStream = data.localvideo
                @emit 'localvideo', data.localvideo
              else
                data
            ),
            es.mapSync( (data) =>
              if data.remotevideo
                @remoteVideoStreams[data.remotevideo.client] = data.remotevideo
                @emit 'remotevideo', data.remotevideo
              else
                data
            ),
            es.mapSync( (data) =>
              if data.emit
                @emit data.topic, data.message
                undefined
              else
                data
            ),
            es.mapSync( (message, callback) ->
              if message.to
                skyclient.send(message.to, 'signaling', message)
              undefined
            )
          )
        )
        skyclient.on 'signaling', (message) ->
          dataChannel.write(message)

Link up to the sky, this will keep a local snapshot of the current room state.
As new clients come in, this state is used to fire off `join` and `leave`
messages, which at the bare minimum are useful for testing.

        @clients = {}
        path = "__rooms__.#{name}"
        roomLink = skyclient.link path, (error, snapshot) =>
          for client, ignore of snapshot?.clients
            if not @clients[client] and client isnt @client
              @clients[client] = true
              dataChannel.write addPeer: client
              @emit 'join', client
          for client, ignore of @clients
            if not snapshot[client]
              @emit 'leave', client

        @localVideoStream = null
        @remoteVideoStreams = {}

Link to our own client in the sky room, this is to update our own state as a
member in the room.

        @clientLink = skyclient.link "#{path}.clients.#{@client}"

        if @clientLink.val
          @clientLink.val.joined = true
          @clientLink.save @clientLink.val
        else
          @clientLink.save joined: true

Messages to all other connected clients in the room. This is a simple topic
and message setup, where messages are strings and the message will be transported
over JSON. This just delegates to the DataChannel.

      send: (topic, message) =>
        @dataChannel.write(
          topic: topic
          message: message
        )
        @

    module.exports = Room
