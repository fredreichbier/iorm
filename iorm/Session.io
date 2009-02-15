DBI

# TODO: cross platform?
DBI initWithDriversPath("/usr/lib/dbd")

Session := Object clone do(
    connection ::= nil

    withSQLite := method(path,
        file := File clone setPath(path)
        conn := DBI with("sqlite3")
        conn optionPut("sqlite3_dbdir", file containingDirectory path asSymbol)
        conn optionPut("dbname", file name asSymbol)
        conn connect
        inst := self clone setConnection(conn)
        return(inst)
    )

    init := method(
        self queue := list()
    )
    
    commit := method(
        /* process all statements in `queue`. Return self. */
        queue foreach(stmt,
            self connection execute(stmt getAsSQL)
        )
        queue = list() # TODO: something like `clear`?
        self
    )

    execute := method(query,
        commit
        executeRaw(query getAsSQL)
    )
    
    executeRaw := method(query,
        self connection execute(query asSymbol)
    )

    executeNow := getSlot("execute") # actually a synonym

    executeDeferred := method(stmt,
        /* append `stmt` to the queue */
        queue append(stmt)
        self
    )

    query := method(qry,
        /* no deferred queries ... return DBIConn */
        connection query(qry getAsSQL)
    )

    printQueue := method(
        queue foreach(stmt,
            stmt getAsSQL println
        )
    )
    
    quote := method(s,
        connection quote(s)
    )
)

