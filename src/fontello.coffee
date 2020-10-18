fs = require 'fs'
needle = require 'needle'
open = require 'open'
path = require 'path'
process = require 'process'
unzip = require 'unzipper'


HOST = 'https://fontello.com'


apiRequest = (options, successCallback, errorCallback) ->
  options.host ?= HOST

  requestOptions = { multipart: true }
  requestOptions.proxy = options.proxy if options.proxy?

  data =
    config:
      file: options.config
      content_type: 'application/json'

  needle.post options.host, data, requestOptions, (error, response, body) ->
    throw error if error
    sessionId = body

    if response.statusCode is 200
      sessionUrl = "#{options.host}/#{sessionId}"
      successCallback? sessionUrl
    else
      errorCallback? response


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
    apiRequest options, (sessionUrl) ->
      open sessionUrl


module.exports = fontello
