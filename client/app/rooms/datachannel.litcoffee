This sets up peer to peer data channels, forming a logical NxN matrix of
connections between all peers.

In comparison to a central hub, reaching all clients is simply N - 1 messages,
whereas with a central hub, there are N messages as the client must send to
the central server before it relays to all clients. This has the effect of
moving bandwidth utilization to the client, away from the server.

    webrtc = require('./webrtcsupport.js')
    _ = require('lodash')
    es = require('event-stream')
    getUserMedia = require('getusermedia')
    tap = require('tap-stream')

    datachannel = (options) ->

Keep a peer connection to every other client in the room. This uses a ...
_substream_ for each connected peer, messages to this data channel will
be relayed to all other peers. Seems simple, the trick is the stream will
only resume once the peer-peer connectivity is established, buffering messages
until that time.

      peerConnections = {}

Our local video stream. This is a shame really that you actually need to *have*
the stream in order to start WebRTC negotiation, rather than just table about
the kind of stream you intend to peer.

      localVideoStream = null

An event stream pipeline, this allows buffering of messages until we are able
to actually process them.  Chose this technique over promises out of pure
fascination with substack's code.

      stream = es.pipeline(
        gate = es.pause().pause(),
        #tap(0),

Adding a peer, this sets up a peer connection with an associated data stream
that is used to relay messages peer to peer in a streamy fashion. The net effect
is that when you write to this overall datachannel stream, messages can be
sent to all attached peers.

        es.map( (object, callback) =>
          if object.addPeer
            otherClient = object.addPeer
            connection = peerConnections[otherClient] =
              new webrtc.PeerConnection(options.peerConfig, options.peerConstraints)
            connection.data = connection.createDataChannel('data', reliable: false)
            connection.addStream(localVideoStream)
            #stream 'adapter' for webrtc data channel
            connection.dataSubstream = es.pipeline(
              connection.gate = es.pause().pause(),
              es.mapSync (message) ->
                console.log 'through', message
                connection.data.send message
                undefined
            )
            connection.data.onopen = ->
              console.log 'data open'
              connection.gate.resume()
            connection.data.onclose = -> connection.dataSubstream.end()
            connection.data.onmessage = (event) ->
              message = JSON.parse(event.data)
              message.emit = true
              console.log 'messagy', message
              stream.write message
            connection.onaddstream = (event) ->
              event.stream.client = otherClient
              stream.write remotevideo: event.stream
            connection.onicecandidate = (event) =>
              if event.candidate
                stream.write
                  from: options.client
                  to: otherClient
                  ice: event.candidate

**Trick**. Connections need to be initiated like a call->answer use the client
identifier as a simple leader election between any two pairs to pick the
caller.

            if options.client > otherClient
              connection.createOffer( ( (sessionDescription) ->
                connection.setLocalDescription sessionDescription, ->
                  stream.write
                    from: options.client
                    to: otherClient
                    offer: sessionDescription
              ), ( (error) ->
                stream.emit 'error', error
              ), options.peerConstraints)

            callback()
          else
            callback(null, object)
        ),

WebRTC negotiation messages for offer/answer/ice.

        es.map( (message, callback) ->
          if message.offer and (connection = peerConnections[message.from])
            connection.setRemoteDescription new webrtc.SessionDescription(message.offer), ->
              connection.createAnswer (sessionDescription) ->
                connection.setLocalDescription sessionDescription, ->
                  stream.write
                    from: options.client
                    to: message.from
                    answer: sessionDescription
                    callback()
                , (error) -> stream.emit 'error', error
          else
            callback(null, message)
        ),
        es.map( (message, callback) ->
          if message.answer and (connection = peerConnections[message.from])
            connection.setRemoteDescription new webrtc.SessionDescription(message.answer), ->
              callback()
            , (error) -> stream.emit 'error', error
          else
            callback(null, message)
        ),
        es.map( (message, callback) ->
          if message.ice and (connection = peerConnections[message.from])
            connection.addIceCandidate(new webrtc.IceCandidate(message.ice))
            callback()
          else
            callback(null, message)
        ),

Topic based messages in the stream sent along to all connected peers over the
peer connections

        es.map( (object, callback) =>
          if object.topic and not object.emit
            message = JSON.stringify(object)
            for otherClient, connection of peerConnections
              connection.dataSubstream.write(message)
            callback()
          else
            callback(null, object)
        )
      )

Start everything up with a local video connection. This opens up this data
channel which itself is _streamy_.

      getUserMedia options.mediaConstraints, (error, video) =>
        if error
          stream.emit 'error', error
        else
          localVideoStream = video
          stream.write localvideo: video
          gate.resume()

      stream

    module.exports = datachannel
