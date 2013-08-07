This is the main entry point, you create a room in VariableSky, which just
springs into existence if needed.

    EventEmitter = require('eventemitter2').EventEmitter2
    DataChannel = require('./datachannel.litcoffee')
    _ = require('lodash')

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
        options = _.extend({}, DEFAULT_OPTIONS, options)

Link up to the sky, this will keep a local snapshot of the current room state.

        @clients = {}
        path = "__rooms__.#{name}"
        roomLink = skyclient.link path, (error, snapshot) =>
          for client, ignore of snapshot?.clients
            if not @clients[client] and client isnt skyclient.client
              @clients[client] = true
              @dataChannel.addPeer(client)
              @emit 'join', client
          for client, ignore of @clients
            if not snapshot[client]
              @emit 'leave', client

Data channel for peer-peer communication.

        @dataChannel = new DataChannel(skyclient, options)
        @remoteVideoStreams = []
        remit = @emit.bind(@)
        @dataChannel.on 'localvideo', (stream) =>
          @localVideoStream = stream
          @emit 'localvideo', stream
        @dataChannel.on 'remotevideo', (stream) =>
          @remoteVideoStreams.push(stream)
          @emit 'remotevideo', stream
        @dataChannel.on '*', (event) ->
          remit this.event, event

Link to our own client in the sky room, this is to update our own state as a
member in the room.

        @clientLink = skyclient.link "#{path}.clients.#{skyclient.client}"

Join this client to a room, which updates the state on the server to let all
room members know we are here.

      join: =>
        console.log 'joining', @name
        if @clientLink.val
          @clientLink.val.joined = true
          @clientLink.save @clientLink.val
        else
          @clientLink.save joined: true
        @

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
