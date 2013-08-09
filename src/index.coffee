colors = require 'colors'
fs = require 'fs'
needle = require 'needle'
{print} = require 'util'
path = require 'path'
program = require 'commander'
pjson = require "#{__dirname}/../package.json"
unzip = require 'unzip'


dirIsValid = (path) ->
  try
    if fs.statSync(path).isDirectory()
      return true
    else
      return false
  catch e
    fs.mkdirSync path
    return true

fontello = ->

  # Command line arguments.
  #
  program
    .version(pjson.version)
    .usage('install')
    .option('--config [path]', 'path to fontello config. defaults to ./config')
    .option('--css [path]', 'path to css directory (optional). if provided, --font option is expected.')
    .option('--font [path]', 'path to font directory (optional). if provided, --css option is expected.')

  program
    .command('install')
    .description('download fontello. without --css and --font flags, the full download is extracted.')
    .action (env, options) ->

      # Check if css and font directories were provided.
      # Create them if they do not exist.
      # Exit if they are not valid directories.
      #
      if program.css and program.font
        unless dirIsValid program.css
          print '--css path provided is not a directory.\n'.red
          process.exit 1

        unless dirIsValid program.font
          print '--font path provided is not a directory.\n'.red
          process.exit 1


      # Begin the download
      #
      host = 'http://fontello.com'

      data =
        config:
          file: program.config or 'config.json'
          content_type: 'application/json'

      needle.post host, data, { multipart: true }, (error, response, body) ->
        throw error if error
        sessionId = body

        if response.statusCode is 200
          zipFile = needle.get("#{host}/#{sessionId}/get", (error, response, body) ->
            throw error if error
          )

          # If css and font directories were provided, extract the contents of
          # the download to those directories. If not, extract the zip file as normal.
          #
          if program.css and program.font
            zipFile
              .pipe(unzip.Parse())
              .on('entry', ((entry) ->
                {path:pathName, type} = entry

                if type is 'File'
                  dirName = path.dirname(pathName).match(/\/([^\/]*)$/)?[1]
                  fileName = path.basename pathName

                  switch dirName
                    when 'css'
                      cssPath = path.join program.css, fileName
                      entry.pipe(fs.createWriteStream(cssPath))
                    when 'font'
                      fontPath = path.join program.font, fileName
                      entry.pipe(fs.createWriteStream(fontPath))
                    else
                      entry.autodrain()
              ))
              .on('finish', (->
                print 'Install complete.\n'.green
              ))

          else
            zipFile
              .pipe(unzip.Extract({ path: '.' }))
              .on('finish', (->
                print 'Install complete.\n'.green
              ))


  program.parse(process.argv)

module.exports = fontello
