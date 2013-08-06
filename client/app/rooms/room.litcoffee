This is the main entry point, you create a room in VariableSky, which just
springs into existence if needed.

    EventEmitter = require('events').EventEmitter
    DataChannel = require('./datachannel.litcoffee')

    DEFAULT_ICE_SERVERS = [
      {url: "stun:stun.l.google.com:19302"}
    ]

    class Room extends EventEmitter
      constructor: (skyclient, name, iceServers) ->
        peerConfig =
          iceServers: iceServers or DEFAULT_ICE_SERVERS

Link up to the sky, this will keep a local snapshot of the current room state.

        path = "__rooms__.#{name}"
        roomLink = skyclient.link path, (error, snapshot) =>
          @state = snapshot

Data channel for sending messages.

        @dataChannel = new DataChannel(skyclient, roomLink, peerConfig)

Link to our own client in the sky room, this is to update our own state.

        @clientLink = skyclient.link "#{path}.clients.#{skyclient.client}"

Join this client to a room, which updates the state on the server to let all
room members know we are here.

      join: ->
        if @clientLink.val
          @clientLink.val.joined = true
          @clientLink.save @clientLink.val
        else
          @clientLink.save joined: true

Messages to all other connected clients in the room. This is a simple topic
and message setup, where messages are strings and the message will be transported
over JSON. This just delegates to the DataChannel.

      send: (topic, message) ->
        @dataChannel.write(
          topic: topic
          message: message
        )

    module.exports = Room
