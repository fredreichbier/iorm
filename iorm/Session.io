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

    withMySQL := method(host, username, password, dbname,
        conn := DBI with("mysql")
        conn optionPut("host", host)
        conn optionPut("username", username)
        conn optionPut("password", password)
        conn optionPut("dbname", dbname)
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
            stmt getAsSQL println
            self connection execute(stmt getAsSQL)
        )
        queue empty
        self
    )

    execute := method(query,
        commit
        query getAsSQL println
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
        qry getAsSQL println
        connection query(qry getAsSQL)
    )

    printQueue := method(
        queue foreach(stmt,
            stmt getAsSQL println
        )
    )
    
    quote := method(s,
        if(s isNil,
            "NULL"
        ,
            connection quote(s asSymbol)
        )
    )
)

