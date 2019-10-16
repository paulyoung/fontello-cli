colors = require 'colors'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
pjson = require path.join(__dirname, '..', 'package.json')
program = require 'commander'
fontello = require path.join(__dirname, '..', 'lib', 'fontello')


dirIsValid = (path) ->
  try
    return fs.statSync(path).isDirectory()
  catch e
    mkdirp.sync path
    return true


config = 'config.json'


program
  .version(pjson.version)
  .usage('[command] [options]')
  .option('--config [path]', 'path to fontello config. defaults to ./config.json')
  .option('--css [path]', 'path to css directory (optional). if provided, --font option is expected.')
  .option('--font [path]', 'path to font directory (optional). if provided, --css option is expected.')
  .option('--host [host]', 'address of fontello instance (optional).')
  .option('--proxy [host]', 'address of the proxy you are behind.')

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
        console.error '--css path provided is not a directory.\n'.red
        process.exit 1

      unless dirIsValid program.font
        console.error '--font path provided is not a directory.\n'.red
        process.exit 1

    fontello.install
      config: program.config or config
      css: program.css
      font: program.font
      host: program.host
      proxy: program.proxy


program
  .command('open')
  .description('open the fontello website with your config file preloaded.')
  .action (env, options) ->
    fontello.open
      config: program.config or config
      host: program.host
      proxy: program.proxy


program.parse process.argv
