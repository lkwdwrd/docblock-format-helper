DocblockFormatter = require './docblockformatter'

module.exports =
  activate: ->
    @formatter = new DocblockFormatter()

  deactivate: ->
    @formatter?.destroy()
    @formatter = null
