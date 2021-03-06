! Copyright (C) 2008, 2010 Eduardo Cavazos, Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel namespaces sequences splitting system accessors
math.functions make io io.files io.pathnames io.directories
io.directories.hierarchy io.launcher io.encodings.utf8 prettyprint
combinators.short-circuit parser combinators math calendar
calendar.format arrays mason.config locals debugger fry
continuations strings io.sockets ;
IN: mason.common

ERROR: no-host-name ;

: short-host-name ( -- string )
    host-name "." split1 drop [ no-host-name ] unless* ;

SYMBOL: current-git-id

: short-running-process ( command -- )
    #! Give network operations and shell commands at most
    #! 30 minutes to complete, to catch hangs.
    >process 30 minutes >>timeout try-output-process ;

HOOK: (really-delete-tree) os ( path -- )

M: windows (really-delete-tree)
    #! Workaround: Cygwin GIT creates read-only files for
    #! some reason.
    [ { "chmod" "ug+rw" "-R" } swap absolute-path suffix short-running-process ]
    [ delete-tree ]
    bi ;

M: unix (really-delete-tree) delete-tree ;

: really-delete-tree ( path -- )
    dup exists? [ (really-delete-tree) ] [ drop ] if ;

: retry ( n quot -- )
    [ iota ] dip
    '[ drop @ f ] attempt-all drop ; inline

: upload-process ( process -- )
    #! Give network operations and shell commands at most
    #! 30 minutes to complete, to catch hangs.
    >process upload-timeout get >>timeout try-output-process ;

:: upload-safely ( local username host remote -- )
    remote ".incomplete" append :> temp
    { username "@" host ":" temp } concat :> scp-remote
    scp-command get :> scp
    ssh-command get :> ssh
    5 [ { scp local scp-remote } upload-process ] retry
    5 [ { ssh host "-l" username "mv" temp remote } short-running-process ] retry ;

: eval-file ( file -- obj )
    dup utf8 file-lines parse-fresh
    [ "Empty file: " swap append throw ] [ nip first ] if-empty ;

: to-file ( object file -- ) utf8 [ . ] with-file-writer ;

: datestamp ( timestamp -- string )
    [
        {
            [ year>> , ]
            [ month>> , ]
            [ day>> , ]
            [ hour>> , ]
            [ minute>> , ]
        } cleave
    ] { } make [ pad-00 ] map "-" join ;

: nanos>time ( n -- string )
    1,000,000,000 /i 60 /mod [ 60 /mod ] dip 3array [ pad-00 ] map ":" join ;

SYMBOL: stamp

: build-dir ( -- path ) builds-dir get stamp get append-path ;

CONSTANT: load-all-vocabs-file "load-everything-vocabs"
CONSTANT: load-all-errors-file "load-everything-errors"

CONSTANT: test-all-vocabs-file "test-all-vocabs"
CONSTANT: test-all-errors-file "test-all-errors"

CONSTANT: help-lint-vocabs-file "help-lint-vocabs"
CONSTANT: help-lint-errors-file "help-lint-errors"

CONSTANT: compiler-errors-file "compiler-errors"
CONSTANT: compiler-error-messages-file "compiler-error-messages"

CONSTANT: boot-time-file "boot-time"
CONSTANT: load-time-file "load-time"
CONSTANT: test-time-file "test-time"
CONSTANT: help-lint-time-file "help-lint-time"
CONSTANT: benchmark-time-file "benchmark-time"
CONSTANT: html-help-time-file "html-help-time"

CONSTANT: benchmarks-file "benchmarks"
CONSTANT: benchmark-error-messages-file "benchmark-error-messages"
CONSTANT: benchmark-error-vocabs-file "benchmark-error-vocabs"

SYMBOL: status-error ! didn't bootstrap, or crashed
SYMBOL: status-dirty ! bootstrapped but not all tests passed
SYMBOL: status-clean ! everything good
