{CompositeDisposable} = require 'atom'

module.exports =
class DocblockFormatter
  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @maybeHandleEvents(editor)

  destroy: ->
    @subscriptions.dispose()

  maybeHandleEvents: (editor) ->
    unhandleEvents = false

    editorObserveGrammar = editor.observeGrammar (grammar) =>
      if grammar.name is 'PHP' or grammar.name is 'JavaScript'
        unhandleEvents = @handleEvents(editor)
      else
        unhandleEvents = unhandleEvents?() ? false

    editorDestroyedSubscription = editor.onDidDestroy =>
      editorObserveGrammar.dispose()
      editorDestroyedSubscription.dispose()
      @subscriptions.remove editorObserveGrammar
      @subscriptions.remove editorDestroyedSubscription

    @subscriptions.add editorObserveGrammar
    @subscriptions.add editorDestroyedSubscription

  handleEvents: (editor) ->
    subscriptions = @subscriptions

    editorTextInsertedInDocblock = editor.onWillInsertText (event) ->
      return unless event.text is "\n" or event.text is "\r\n"

      isDocblockRow = (row) ->
        return false unless row >= 0 and row <= editor.getLastBufferRow()
        currentLine = editor.lineTextForBufferRow(row).trim()
        return currentLine isnt '*/' and currentLine.substr(0, 1) is '*'

      isInDocblock = (row) ->
        return false unless isDocblockRow(row)
        searchBackwards = row
        searchForward = row
        while isDocblockRow(--searchBackwards)
          continue
        while isDocblockRow(++searchForward)
          continue
        return editor.lineTextForBufferRow(searchBackwards).trim() is '/**' and editor.lineTextForBufferRow(searchForward).trim() is '*/'

      currentRow = editor.getCursorBufferPosition().row
      return unless isInDocblock(currentRow)

      currentRowText = editor.lineTextForBufferRow(currentRow)
      currentRowWhitespace = getWhiteSpace currentRowText
      event.cancel()
      editor.deleteToBeginningOfLine()
      editor.insertText( currentRowWhitespace + currentRowText.trim() + "\n" + currentRowWhitespace + "* " )

    editorTextInsertedMakeDocblock = editor.onDidInsertText (event) ->
      return unless event.text is "\n" or event.text is "\r\n"
      currentLine = editor.lineTextForBufferRow( event.range.start.row )
      return unless currentLine.trim() is '/**'
      whitespace = getWhiteSpace currentLine
      editor.insertText( whitespace + " * ")
      endPos = editor.getCursorBufferPosition()
      editor.insertText("\n" + whitespace + " */")
      editor.setCursorBufferPosition(endPos)


    editorTextInsertedDocblockEnd = editor.onDidInsertText (event) ->
      return unless event.text is "\n" or event.text is "\r\n"

      lastLine = editor.lineTextForBufferRow(event.range.start.row);
      return unless lastLine.trim() is '*/'

      whiteSpace = getWhiteSpace lastLine
      editor.deleteToBeginningOfLine()
      editor.insertText( whiteSpace.substr(0, whiteSpace.length-1) )

    removeSubscription = ->
      editorTextInsertedMakeDocblock.dispose()
      editorTextInsertedInDocblock.dispose()
      editorTextInsertedDocblockEnd.dispose()
      editorDestroyedSubscription.dispose()
      subscriptions.remove(editorTextInsertedMakeDocblock)
      subscriptions.remove(editorTextInsertedInDocblock)
      subscriptions.remove(editorTextInsertedDocblockEnd)
      subscriptions.remove(editorDestroyedSubscription)

    editorDestroyedSubscription = editor.onDidDestroy removeSubscription

    subscriptions.add(editorTextInsertedMakeDocblock)
    subscriptions.add(editorTextInsertedInDocblock)
    subscriptions.add(editorTextInsertedDocblockEnd)
    subscriptions.add(editorDestroyedSubscription)

    getWhiteSpace = ( indentedString ) ->
      whitespace = indentedString.match(/^\s+/)
      if whitespace then whitespace[0] else ''

    return removeSubscription
