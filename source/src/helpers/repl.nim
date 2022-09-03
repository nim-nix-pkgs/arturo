######################################################
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2022 Yanis Zafirópulos
#
# @file: helpers/repl.nim
######################################################

#=======================================
# Libraries
#=======================================

import os

when not defined(WEB):

    import sequtils, strutils, sugar, tables
    import extras/linenoise
    import vm/values/value

    #=======================================
    # Constants
    #=======================================

    const
        ReplHistoryPath = joinPath(joinPath(getHomeDir(), ".arturo"), "history.txt")

    #=======================================
    # Variables
    #=======================================

    var
        ReplInitialized = false

    #=======================================
    # C Exports
    #=======================================

    var
        completions {.exportc.} : ValueArray
        hints       {.exportc.} : ValueDict

    #=======================================
    # Helpers
    #=======================================

    # TODO(Helpers/repl) Add Ctrl+D capabilities for REPL
    #  Our REPL should be able to handle Ctrl+D, but it's not working yet. Given that it's based on the LineNoise library, this the place we should start looking first.
    #  labels: helpers, 3rd-party, enhancement

    # TODO(Helpers/repl) Add multi-line copy-paste capabilities for REPL
    #  It would be great to be able to copy-paste multi-line text into our REPL and handle it properly!
    #  As with Ctrl+D, given that it's based on the LineNoise library, this the place we should start looking first.
    #  labels: helpers, 3rd-party, enhancement

    proc initRepl*(path: string, completionsArray: ValueArray = @[], hintsTable: ValueDict = initOrderedTable[string,Value]()) =
        completions = completionsArray
        hints = hintsTable

        proc completionsCback(buf: cstring; lc: ptr LinenoiseCompletions) {.cdecl.} =
            var token = $(buf)
            var copied = strip($(buf))
            let tokenParts = splitWhitespace(token)
            if tokenParts.len >= 1:
                token = tokenParts[^1]
                copied.removeSuffix(token)
                for item in completions.map((x) => x.s).filter((x) => x.startsWith(token)):
                    linenoiseAddCompletion(lc, (copied & item).cstring)


        proc hintsCback(buf: cstring; color: var cint; bold: var cint): cstring {.cdecl.} =
            var token = $(buf)
            let tokenParts = splitWhitespace(token)
            if tokenParts.len >= 1:
                token = tokenParts[^1]
                let tokenHint = hints.getOrDefault(token, VNOTHING)
                if tokenHint != VNOTHING:
                    color = 35
                    bold = 0
                    return (cstring)" " & tokenHint.s
            return nil
            
        if not ReplInitialized:
            if not fileExists(parentDir(path)):
                createDir(parentDir(path))
            discard linenoiseHistoryLoad(path)

            linenoiseSetCompletionCallback(cast[ptr LinenoiseCompletionCallback](completionsCback))
            linenoiseSetHintsCallback(cast[ptr LinenoiseHintsCallback](hintsCback))

            ReplInitialized = true

    #=======================================
    # Methods
    #=======================================

    proc replInput*(
        prompt: string, 
        historyPath: string = ReplHistoryPath, 
        completionsArray: ValueArray = @[],
        hintsTable: ValueDict = initOrderedTable[string,Value]()
    ): string =
        initRepl(historyPath, completionsArray, hintsTable)

        let got = linenoiseReadLine(prompt.cstring)
        linenoiseHistoryAdd(got)
        discard linenoiseHistorySave(historyPath)
        result = $(got)

        free(got)