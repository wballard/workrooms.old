This is the server starting point. This is a single page app.

* static root single page
* less pipeline to get styles
* browserify pipeline to get javascript code

    express = require('express')
    http = require('http')
    path = require('path')
    less = require('less-middleware')
    enchilada = require('enchilada')

    app = express()
    root = path.join(__dirname, '..')
    port = process.env['NINEBOX_PORT'] or 4000

    bowerPath = path.join(__dirname, '..', 'bower_components')
    bootstrapPath = path.join(__dirname, '..', 'bower_components', 'bootstrap')
    fontawesomePath = path.join(__dirname, '..', 'bower_components', 'font-awesome')
    app.use less(
        src: path.join(root, 'client')
        paths: [
            path.join(bootstrapPath, 'less')
            path.join(fontawesomePath, 'less')
            path.join(root, 'client', 'less')
            bowerPath
        ]
        dest: path.join(root, 'var', 'public')
        compress: true
        debug: false
    )

    app.use enchilada(
        src: path.join(root, 'client')
        debug: false
        compress: false
        transforms: [require('coffeeify')]
    )

    app.get '/', (req, res, next) ->
        res.sendfile path.join(root, 'client', 'index.html')

    app.use '/views', express.static(path.join(root, 'client', 'views'))
    app.use '/images', express.static(path.join(root, 'client', 'images'))
    app.use '/font', express.static(path.join(fontawesomePath, 'font'))
    app.use express.static(path.join(root, 'var', 'public'))

    httpServer = http.createServer(app)

    console.log "listening #{port}"
    httpServer.listen(port)

