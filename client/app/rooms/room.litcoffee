This is the main entry point, you create a room in VariableSky, which just
springs into existence if needed.

    EventEmitter = require('events').EventEmitter

    class Room extends EventEmitter
      constructor: (skyclient, name) ->
        @client = skyclient.client

Link up to the sky, this will keep a local snapshot of the current room state.

        path = "__rooms__.#{name}"
        roomLink = skyclient.link path, (error, snapshot) =>
          @state = snapshot
          @emit 'update', snapshot

Link to our own slice of the sky, this is what will be updated by this client
instance of a room.

        slice = "#{path}.#{skyclient.client}"
        @sliceLink = skyclient.link slice

      join: ->
        @sliceLink.save joined: true

    module.exports = Room
