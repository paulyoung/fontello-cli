fs = require 'fs'
needle = require 'needle'
program = require 'commander'
pjson = require "#{__dirname}/../package.json"
unzip = require 'unzip'

fontello = ->

  # Command line arguments.
  #
  program
    .version(pjson.version)
    .usage('install')
    .option('-c, --config [path]', 'path to fontello config')

  program
    .command('install')
    .description('download fontello')
    .action (env, options) ->
      host = 'http://fontello.com'

      data =
        config:
          file: program.config or 'config.json'
          content_type: 'application/json'

      needle.post host, data, { multipart: true }, (error, response, body) ->
        throw error if error
        sessionId = body

        if response.statusCode is 200
          needle.get("#{host}/#{sessionId}/get", (error, response, body) ->
            throw error if error
          )
          .pipe unzip.Extract({ path: '.' })


  program.parse(process.argv)

module.exports = fontello
