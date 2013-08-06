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


      constructor: (roomLink, clientLink, peerConfig) ->
        constraints =
          mandatory:
            OfferToReceiveAudio: false,
            OfferToReceiveVideo: false
          optional: [
            {RtpDataChannels: true}
          ]

Hooked in to the room link, this is how all the peers are discovered. This kind
of model converges on connection rather rather than responding to messages. The
idea is that it will be a bit more reliable in the face of disconnects.

        peerChannels = {}
        roomLink.on 'data', (snapshot) ->

          console.log snapshot
          clientData = clientLink.val or {}
          clientData.answers = clientData.answers or {}
          clientData.offers = clientData.offers or {}
          clientData.iceCandidates = clientData.iceCandidates or {}

All important ID, to tell 'this side' of the connection.

          client = clientLink.connection.client

          for otherClient, otherClientData of snapshot?.clients
            do ->
              if otherClient is client
                #skip yourself

This is the most important case, set up a peer connection for each other
client, think of this as a peer matrix. The interesting bit here is capturing
all the ICE candidates to be shared with the peer.

              else
                channel = peerChannels[otherClient]
                if not channel
                  channel = peerChannels[otherClient] = new webrtc.PeerConnection(peerConfig, constraints)
                  channel.onicecandidate = (event) ->
                    candidates = clientData.iceCandidates[otherClient] or []
                    if event.candidate
                      candidates.push(event.candidate)
                      clientData.iceCandidates[otherClient] = candidates
                      clientLink.save(clientData)
                  channel.oniceconnectionstatechange = (event) ->
                    console.log 'ICE', event
                  channel.onopen = (event) ->
                    console.log 'OPEN', event

Set up the actual data channel.

                  channel.ondatachannel = (event) ->
                    console.log 'connected'
                  channel.data = channel.createDataChannel 'peerdata', reliable: false

Start the negotiation sequence here when asked by the peer connection. This
uses variable sky to transmit all the SDP data.

                  channel.onnegotiationneeded = (event) ->
                    console.log 'NEGOTITATE'
                    channel.createOffer ( (sessionDescription) =>
                      clientData.offers[otherClient] = sessionDescription
                      clientLink.save(clientData)
                    ), ( (error) =>
                      @emit 'error', error
                    ), constraints

Look to complete offer/answer pairs. This negotiation terminates when the
remote description is an answer, indicating both sides have exchanged
offer/answer pairs.

                offerToMe = otherClientData?.offers?[client]
                answerToMe = otherClientData?.answers?[client]
                if offerToMe and not channel.remoteDescription
                  console.log 'answering'
                  channel.setRemoteDescription new webrtc.SessionDescription(offerToMe), ->
                    channel.createAnswer ( (sessionDescription) ->
                      console.log 'answer'
                      clientData.answers[otherClient] = sessionDescription
                      channel.setLocalDescription sessionDescription, ->
                        clientLink.save(clientData)
                    ), ( (error) =>
                      console.log error
                      @emit 'error', error
                    ), constraints
                if answerToMe and not channel?.remoteDescription?.type is 'answer'
                  console.log 'complete'
                  channel.setRemoteDescription new webrtc.SessionDescription(answerToMe), =>
                    @emit 'connected', clientLink.connection.client, otherClient

And the all important ICE candidates from the peer, this actually connects us.

                for iceCandidate in (otherClientData?.iceCandidates?[client] or [])
                  console.log 'Adding ICE'
                  channel.addIceCandidate new webrtc.IceCandidate(iceCandidate)

Get a named channel, this allows messages to be subdivided into groups.

        @channel = (name) ->
          send: ->
          on: ->
          off: ->

    module.exports = DataChannel
