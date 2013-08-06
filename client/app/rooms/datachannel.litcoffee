This sets up peer to peer data channels for the exchange of simple messages.
A peer data channel is set up with each other client joined to the room, so
message flows are from the client.

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

Handle the webrtc events, this controls the lifecycle of establishing a
connection.

                  connection.onicecandidate = (event) ->
                    skyclient.send(otherClient, 'ice', event.candidate)

                  connection.onnegotiationneeded = (event) ->
                    if skyclient.starter
                      connection.createOffer( (sessionDescription) ->
                        connection.setLocalDescription sessionDescription, ->
                          skyclient.send(otherClient, 'offer', sessionDescription)
                      , onError, constraints)

                  connection.oniceconnectionstatechange =  ->
                    console.log 'ICE', connection
                  connection.ondatachannel = ->
                    console.log 'DATA', connection

Set up the actual data channel.

                  connection.ondatachannel = (event) ->
                    console.log 'connected'
                  connection.data = connection.createDataChannel 'peerdata', reliable: false
                  connection.data.onopen = ->
                    console.log 'open data', connection

Respond to negotiation messages.

        skyclient.on 'ice', (candidate, from) ->
          connection = peerConnections[from]
          if connection
            if candidate
              connection.addIceCandidate(new webrtc.IceCandidate(candidate))
            else
              console.log 'ice complete', connection

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
