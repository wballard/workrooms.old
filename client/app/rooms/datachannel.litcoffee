This sets up peer to peer data channels, forming a logical NxN matrix of
connections between all peers.

In comparison to a central hub, reaching all clients is simply N - 1 messages,
whereas with a central hub, there are N messages as the client must send to
the central server before it relays to all clients. This has the effect of
moving bandwidth utilization to the client, away from the server.

    EventEmitter = require('events').EventEmitter
    webrtc = require('./webrtcsupport.js')
    _ = require('lodash')

    class DataChannel extends EventEmitter
      constructor: (skyclient, roomLink, peerConfig) ->
        constraints =
          optional: [
            {RtpDataChannels: true}
          ]

All important ID, to tell 'this side' of the connection.

        client = skyclient.client

        onError = (error) =>
          console.log error
          @emit 'error', error

Keep a peer connection to every other client in the room.

        peerConnections = {}

Hooked in to the room link, this is how all the peers are discovered. This kind
of model converges on connection rather rather than responding to messages. The
idea is that it will be a bit more reliable in the face of disconnects.

        roomLink.on 'data', (snapshot) ->
          for otherClient, ignore of snapshot?.clients
            if otherClient is client
              #skip yourself
            else
              connection = peerConnections[otherClient]
              if not connection
                do ->
                  connection = peerConnections[otherClient] = new webrtc.PeerConnection(peerConfig, constraints)

ICE Candidates provide address information for eventual connection.

                  connection.onicecandidate = (event) ->
                    skyclient.send(otherClient, 'ice', event.candidate)

This is a trick. Connections need to be initiated like a 'caller' and answerer,
so use the identifier as a simple leader election between any two pairs to pick
the caller.

                  connection.onnegotiationneeded = (event) ->
                    console.log client > otherClient
                    if client > otherClient
                      connection.createOffer( (sessionDescription) ->
                        connection.setLocalDescription sessionDescription, ->
                          skyclient.send(otherClient, 'offer', sessionDescription)
                      , onError, constraints)

Set up the actual data channel.

                  connection.ondatachannel = (event) ->
                    console.log 'connected'
                  connection.data = connection.createDataChannel 'peerdata', reliable: false
                  connection.data.onopen = ->
                    console.log 'open data'
                    connection.data.send('hi')
                  connection.data.onmessage = (event) ->
                    console.log 'message', event

Respond to negotiation messages.

        skyclient.on 'ice', (candidate, from) ->
          connection = peerConnections[from]
          if connection
            if candidate
              connection.addIceCandidate(new webrtc.IceCandidate(candidate))

        skyclient.on 'offer', (sessionDescription, from) ->
          connection = peerConnections[from]
          if connection
            console.log 'answering'
            connection.setRemoteDescription new webrtc.SessionDescription(sessionDescription), ->
              connection.createAnswer (sessionDescription) ->
                connection.setLocalDescription sessionDescription, ->
                  skyclient.send(from, 'answer', sessionDescription)
                , onError

        skyclient.on 'answer', (sessionDescription, from) ->
          connection = peerConnections[from]
          if connection
            console.log 'answer', sessionDescription
            connection.setRemoteDescription new webrtc.SessionDescription(sessionDescription), =>
              @emit 'connected', client, from
            , onError

Get a named channel, this allows messages to be subdivided into groups.

        @channel = (name) ->
          send: ->
          on: ->
          off: ->

    module.exports = DataChannel
