fs = require 'fs'
needle = require 'needle'
open = require 'open'
path = require 'path'
process = require 'process'
unzip = require 'unzipper'


HOST = 'https://fontello.com'

getSession = (options, requestOptions, successCallback, errorCallback) ->
  console.log 'Creating a new session'.green;
  data =
    config:
      file: options.config
      content_type: 'application/json'

  needle.post options.host, data, requestOptions, (error, response, body) ->
    throw error if error
    sessionId = body

    if response.statusCode is 200
      fs.writeFile '.fontello-session', sessionId, (err) ->
          if not err
            console.log 'Session was saved as .fontello-session \n'.green;
          else
            console.error err + "\n";
      sessionUrl = "#{options.host}/#{sessionId}"
      successCallback? sessionUrl
    else
      errorCallback? response

apiRequest = (options, successCallback, errorCallback) ->
  options.host ?= HOST

  requestOptions = { multipart: true }
  requestOptions.proxy = options.proxy if options.proxy?
  if fs.existsSync(".fontello-session")
    stats = fs.statSync(".fontello-session")

    timeDiff = Math.abs(new Date().getTime() - stats.mtime.getTime());

    if timeDiff < (1000 * 3600 * 24)
      console.log 'Using .fontello-session'.green
      sessionId = fs.readFileSync('.fontello-session');
      sessionUrl = "#{options.host}/#{sessionId}"
      return successCallback? sessionUrl


  getSession(options, requestOptions, successCallback, errorCallback)



fontello =

  install: (options) ->

    # Begin the download
    #
    apiRequest options, (sessionUrl) ->
      requestOptions = { follow: 10 }
      requestOptions.proxy = options.proxy if options.proxy?

      zipFile = needle.get("#{sessionUrl}/get", requestOptions, (error, response, body) ->
        throw error if error
        throw "Failed. Response Code [${response.statusCode}] from ${sessionUrl}/get" if (response.statusCode != 200)
      )

      # If css and font directories were provided, extract the contents of
      # the download to those directories. If not, extract the zip file as normal.
      #
      if options.css and options.font
        zipFile
          .pipe(unzip.Parse())
          .on('entry', ((entry) ->
            {path:pathName, type} = entry

            if type is 'File'
              dirName = path.dirname(pathName).match(/\/([^\/]*)$/)?[1]
              fileName = path.basename pathName

              switch dirName
                when 'css'
                  cssPath = path.join options.css, fileName
                  entry.pipe(fs.createWriteStream(cssPath))
                when 'font'
                  fontPath = path.join options.font, fileName
                  entry.pipe(fs.createWriteStream(fontPath))
                else
                  entry.autodrain()
          ))
          .on('finish', (->
            console.log 'Install complete.\n'.green
          ))

      else
        zipFile
          .pipe(unzip.Extract({ path: process.cwd() }))
          .on('finish', (->
            console.log 'Install complete.\n'.green
          ))


  open: (options) ->
    apiRequest options, ((sessionUrl) ->
      console.log "Your browser should open itself, otherwise you can open the following URL manually: #{sessionUrl}\n".green
      open sessionUrl
    )


module.exports = fontello
