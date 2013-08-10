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
        @on '*', () ->
          console.log this.event, arguments

        onError = (error) =>
          @emit 'error', error

All important ID, to tell 'this side' of the connection.

        @client = @skyclient.client

Keep a peer connection to every other client in the room. This uses a ...
_substream_ for each connected peer, messages to this data channel will
be relayed to all other peers. Seems simple, the trick is the stream will
only resume once the peer-peer connectivity is established, buffering messages
until that time.

**Trick**. Connections need to be initiated like a 'caller' and answerer, so
use the client identifier as a simple leader election between any two pairs to
pick the caller.

        @peerConnections = {}
        addAPeer = (otherClient) =>
          @emit 'adding', otherClient
          connection = @peerConnections[otherClient] =
            new webrtc.PeerConnection(@options.peerConfig, @options.peerConstraints)
          connection.sendstream = es.pipeline(
            connection.sendstreamgate = es.pause(),
            es.map( (message, callback) ->
              connection.data.send(message)
              callback()
            )
          )
          connection.sendstreamgate.pause()
          connection.data = connection.createDataChannel('data', reliable: false)
          connection.addStream(@localVideoStream)
          connection.data.onopen = =>
            connection.sendstreamgate.resume()
          connection.data.onclose = =>
            connection.sendstreamgate.pause()
          connection.data.onmessage = (event) =>
            @inbound.write(event.data)
          connection.onaddstream = (event) =>
            @emit 'remotevideo', event.stream
          connection.onicecandidate = (event) =>
            if event.candidate
              @skyclient.send(otherClient, 'ice', event.candidate)

          if @client > otherClient
            @emit 'negotiate', otherClient
            connection.createOffer( (sessionDescription) =>
              connection.setLocalDescription sessionDescription, =>
                @skyclient.send(otherClient, 'offer', sessionDescription)
            , @onError, @options.peerConstraints)

An event stream pipeline, this allows buffering of messages until the channel
has the local stream callbacks, particularly for video. Chose this technique
over promises out of pure fascination with substack's code.

        @outbound = es.pipeline(
          outboundGate = es.pause().pause(),
          es.map( (object, callback) =>
            if object.addPeer
              addAPeer(object.addPeer)
              callback()
            else
              callback(null, object)
          ),
          es.stringify(),
          es.map( (message, callback) =>
            for otherClient, connection of @peerConnections
              connection.sendstream.write(message)
            callback()
          )
        )
        @inbound = es.pipeline(
          es.parse(),
          es.mapSync( (object) =>
            @emit object.topic, object.message
          )
        )

Respond to negotiation messages. These are coming in from every other client
the `from` bit, which is then used as a key.

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

Start everything up with a local video connection. This opens up this data
channel which itself is _streamy_.

        getUserMedia @options.mediaConstraints, (error, stream) =>
          if error
            @emit 'error', error
          else
            @localVideoStream = stream
            @emit 'localvideo', stream
            outboundGate.resume()

Write a general purpose message to this stream in {topic:, message:} format. This
will be delivered to all connected peers.

      write: (message) ->
        @outbound.write(message)

    module.exports = DataChannel
