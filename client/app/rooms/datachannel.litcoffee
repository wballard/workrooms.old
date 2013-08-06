This sets up peer to peer data channels, forming a logical NxN matrix of
connections between all peers.

In comparison to a central hub, reaching all clients is simply N - 1 messages,
whereas with a central hub, there are N messages as the client must send to
the central server before it relays to all clients. This has the effect of
moving bandwidth utilization to the client, away from the server.

    EventEmitter = require('events').EventEmitter
    webrtc = require('./webrtcsupport.js')
    _ = require('lodash')
    es = require('event-stream')

    class DataChannel extends EventEmitter
      constructor: (skyclient, roomLink, peerConfig) ->
        constraints =
          mandatory:
            OfferToReceiveAudio: true
            OfferToReceiveVideo: true
          optional: [
            {RtpDataChannels: true}
          ]

All important ID, to tell 'this side' of the connection.

        client = skyclient.client

        onError = (error) =>
          @emit 'error', error

Keep a peer connection to every other client in the room.

        peerConnections = {}

An event stream pipeline, this allows buffering of send messages until the
local data channel is connected at all. This stream is lossy in that new data
connections can and will come on line, messages sent before they come on line
won't get to them.

        @outbound = es.pipeline(
          es.map( (object, callback) ->
            callback(null, JSON.stringify(object))
          ),
          es.map( (message, callback) ->
            for otherClient, connection of peerConnections
              connection.sendstream.write(message)
            callback()
          )
        )
        @inbound = es.pipeline(
          es.map( (message, callback) ->
            callback(null, JSON.parse(message))
          ),
          es.map( (object, callback) ->
            console.log object, 'a'
            callback()
          )
        )


Hooked in to the room link, this is how all the peers are discovered. This kind
of model converges on connection rather rather than responding to messages. The
idea is that it will be a bit more reliable in the face of disconnects.

        roomLink.on 'data', (snapshot) =>
          for otherClient, ignore of snapshot?.clients
            if otherClient is client
              #skip yourself
            else
              connection = peerConnections[otherClient]
              if not connection
                do =>
                  connection = peerConnections[otherClient] = new webrtc.PeerConnection(peerConfig, constraints)

ICE Candidates provide address information for eventual connection.

                  connection.onicecandidate = (event) ->
                    skyclient.send(otherClient, 'ice', event.candidate)

This is a trick. Connections need to be initiated like a 'caller' and answerer,
so use the identifier as a simple leader election between any two pairs to pick
the caller.

                  connection.onnegotiationneeded = (event) ->
                    if client > otherClient
                      connection.createOffer( (sessionDescription) ->
                        connection.setLocalDescription sessionDescription, ->
                          skyclient.send(otherClient, 'offer', sessionDescription)
                      , onError, constraints)

Set up the topic 'send' channel.

                  connection.sendstream = es.pipeline(
                    connection.sendstreamgate = es.pause(),
                    es.map( (message, callback) ->
                      connection.data.send(message)
                      callback()
                    )
                  )
                  connection.sendstreamgate.pause()

This is the actual data channel.

                  connection.data = connection.createDataChannel 'data', reliable: false
                  connection.data.onopen = =>
                    connection.sendstreamgate.resume()
                  connection.data.onclose = =>
                    connection.sendstreamgate.pause()
                  connection.data.onmessage = (event) =>
                    @inbound.write(event.data)

Respond to negotiation messages.

        skyclient.on 'ice', (candidate, from) ->
          connection = peerConnections[from]
          if connection
            if candidate
              connection.addIceCandidate(new webrtc.IceCandidate(candidate))

        skyclient.on 'offer', (sessionDescription, from) ->
          connection = peerConnections[from]
          if connection
            connection.setRemoteDescription new webrtc.SessionDescription(sessionDescription), ->
              connection.createAnswer (sessionDescription) ->
                connection.setLocalDescription sessionDescription, ->
                  skyclient.send(from, 'answer', sessionDescription)
                , onError

        skyclient.on 'answer', (sessionDescription, from) ->
          connection = peerConnections[from]
          if connection
            connection.setRemoteDescription new webrtc.SessionDescription(sessionDescription), =>
              @emit 'connected', client, from
            , onError

      write: (message) ->
        @outbound.write(message)

    module.exports = DataChannel
