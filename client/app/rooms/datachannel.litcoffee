This sets up peer to peer data channels, forming a logical NxN matrix of
connections between all peers.

In comparison to a central hub, reaching all clients is simply N - 1 messages,
whereas with a central hub, there are N messages as the client must send to
the central server before it relays to all clients. This has the effect of
moving bandwidth utilization to the client, away from the server.

    EventEmitter = require('eventemitter2').EventEmitter2
    webrtc = require('./webrtcsupport.js')
    _ = require('lodash')
    es = require('event-stream')
    getUserMedia = require('getusermedia')

    class DataChannel extends EventEmitter
      constructor: (@skyclient, @options) ->
        super wildcard: true

All important ID, to tell 'this side' of the connection.

        @client = @skyclient.client

Keep a peer connection to every other client in the room.

        @peerConnections = {}

An event stream pipeline, this allows buffering of send messages until the
local data channel is connected at all. This stream is lossy in that new data
connections can and will come on line, messages sent before they come on line
won't get to them. Incoming messages are turned into events, the thought being
that more folks are used the 'on' style API than streaming.

        @outbound = es.pipeline(
          es.map( (object, callback) =>
            callback(null, JSON.stringify(object))
          ),
          es.map( (message, callback) =>
            for otherClient, connection of @peerConnections
              connection.sendstream.write(message)
            callback()
          )
        )
        @inbound = es.pipeline(
          es.map( (message, callback) =>
            callback(null, JSON.parse(message))
          ),
          es.map( (object, callback) =>
            @emit object.topic, object.message
            callback()
          )
        )

Respond to negotiation messages.

        @skyclient.on 'ice', (candidate, from) =>
          connection = @peerConnections[from]
          if connection
            if candidate
              connection.addIceCandidate(new webrtc.IceCandidate(candidate))

        @skyclient.on 'offer', (sessionDescription, from) =>
          connection = @peerConnections[from]
          if connection
            connection.setRemoteDescription new webrtc.SessionDescription(sessionDescription), =>
              connection.createAnswer (sessionDescription) =>
                connection.setLocalDescription( sessionDescription,( () =>
                  @skyclient.send(from, 'answer', sessionDescription)
                ), @onError)

        @skyclient.on 'answer', (sessionDescription, from) =>
          connection = @peerConnections[from]
          if connection
            connection.setRemoteDescription(new webrtc.SessionDescription(sessionDescription), ( ()=>
            ), @onError)

Error handling, this is here to emit and log for the time being.

      onError: (error) =>
        console.log error
        @emit 'error', error

Add a new peer connection to another client.

      addPeer: (otherClient) =>

Hooked in to the room link, this is how all the peers are discovered. This kind
of model converges on connection rather rather than responding to messages. The
idea is that it will be a bit more reliable in the face of disconnects.

        connection = @peerConnections[otherClient] =
          new webrtc.PeerConnection(@options.peerConfig, @options.peerConstraints)

This is the actual data channel. Incoming messages are routed to a processing
stream to be turned into events as they are received.

        connection.data = connection.createDataChannel('data', reliable: false)
        connection.data.onopen = =>
          connection.sendstreamgate.resume()
        connection.data.onclose = =>
          connection.sendstreamgate.pause()
        connection.data.onmessage = (event) =>
          @inbound.write(event.data)

Set up the topic 'send' stream that goes over the data channel. This is
initially paused until the connection is open so that messages are buffered per
peer.

        connection.sendstream = es.pipeline(
          connection.sendstreamgate = es.pause(),
          es.map( (message, callback) ->
            connection.data.send(message)
            callback()
          )
        )
        connection.sendstreamgate.pause()

Set up a conference audio/video stream.

        getUserMedia @options.mediaConstraints, (error, stream) =>
          if error
            @onError(error)
          else
            @emit 'localvideo', stream
            connection.addStream(stream)

This is a trick. Connections need to be initiated like a 'caller' and answerer,
so use the identifier as a simple leader election between any two pairs to pick
the caller.

            if @client > otherClient
              console.log 'negotiate!'
              connection.createOffer( (sessionDescription) =>
                connection.setLocalDescription sessionDescription, =>
                  @skyclient.send(otherClient, 'offer', sessionDescription)
              , @onError, @options.peerConstraints)

Listen for remote media streams.

        connection.onaddstream = (event) =>
          @emit 'remotevideo', event.stream

ICE Candidates provide address information for eventual connection.

        connection.onicecandidate = (event) =>
          @skyclient.send(otherClient, 'ice', event.candidate)



Write a general purpose message to this stream in {topic:, message:} format. This
will be delivered to all connected peers.

      write: (message) ->
        @outbound.write(message)

    module.exports = DataChannel
