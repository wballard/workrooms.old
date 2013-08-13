This is the main entry point, you create a room in VariableSky, which just
springs into existence if needed. Rooms track all the attached clients.

Rooms are _streamy_, but also fire off some events:

* localvideo
* remotevideo
* _topic_ messages relayed

This event firing makes it a tiny bit easier to hook up to clients.

As a stream, it is just writable, all events are eaten at a dead end
of the pipeline. So, don't try to read from this or pipe it.

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

Hook into a room with this function.

    room = (skyclient, name, options) ->
      options = _.extend({}, DEFAULT_OPTIONS, options)
      options.client = options.client or skyclient.client

Data channel for peer-peer communication.

      dataChannel = datachannel(options)
      emit = ->
        dataChannel.emit.apply dataChannel, arguments
      remoteVideoStreams = {}
      localVideoStream = {}

The room itself is a stream pipeline of command handling.

      roomStream = es.pipeline(
        es.mapSync( (data) ->
          if data.localvideo
            localVideoStream = data.localvideo
            localVideoStream.live = true
            #hack for testing visually
            if HACK
              remoteVideoStreams[data.localvideo.client] = data.localvideo
            #end hack
            emit 'localvideo', data.localvideo
            synchMetadata()
          else
            data
        ),
        es.mapSync( (data) ->
          if data.remotevideo
            remoteVideoStreams[data.remotevideo.client] = data.remotevideo
            data.remotevideo.live = true
            emit 'remotevideo', remoteVideoStreams
            synchMetadata()
          else
            data
        ),
        es.mapSync( (data) ->
          if data is dataChannel.localState
            clientLink.save data
            undefined
          else
            data
        ),
        es.mapSync( (data) ->
          if data.emit
            emit data.topic, data.message
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

All connected, data in the channel is processed by this room.

      dataChannel.pipe(roomStream)

Variable sky signalling channel forwards to the data channel for processing.
This is the WebRTC _signaling server_ bit. This is peer-peer over a streaming
message channel, not reflected in a VariableSky variable, as there is no point
in all clients seeing it.

      skyclient.on 'signaling', (message) ->
        dataChannel.write(message)

Link up to the sky, this will keep a local snapshot of the current room state.
As new clients come in, this state is used to fire off `join` and `leave`
messages, which at the bare minimum are useful for testing.

      clients = {}
      path = "__rooms__.#{name}"
      roomData = {}
      roomLink = skyclient.link path, (error, snapshot) =>
        roomData = snapshot
        for client, ignore of snapshot?.clients
          if not clients[client] and client isnt options.client
            clients[client] = true
            dataChannel.write addPeer: client
            emit 'join', client
        synchMetadata()

Metadata, moved on to the video streams themselves. A bit easier to use with
Angular like this, allowing the video stream itself to be put into scopes.

      synchMetadata =  ->
        allStreams = {}
        if localVideoStream
          allStreams[options.client] = localVideoStream
        allStreams = _.extend(allStreams, remoteVideoStreams)
        for client, metadata of roomData?.clients
          if stream = allStreams[client]
            stream.muteAudio = metadata.muteAudio or false
            stream.muteVideo = metadata.muteVideo or false
            stream.width = options.mediaConstraints.video.mandatory.maxWidth
            stream.height = options.mediaConstraints.video.mandatory.maxHeight
          else
            remoteVideoStreams[client] = {}
        emit 'synch', localVideoStream, remoteVideoStreams

Link to our own client in the sky room, this is to update our own state as a
member in the room.

      dataChannel.clientLinkPath = "#{path}.clients.#{options.client}"
      clientLink = skyclient.link dataChannel.clientLinkPath

      clientLink.save
        joined: Date.now()

And that's it, we are all set up.

      dataChannel

    module.exports = room
