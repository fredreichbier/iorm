Query := Object clone do(
    session ::= nil

    getAsSQL := method(
        ""
    )
)

Select := Object clone do(
    table ::= nil
    fields ::= nil 
    condition ::= nil

    getAsSQL := method(
        field_names := nil
        if(fields isNil,
            field_names = "*"
        ,
            field_names = fields map(f, f getNameAsSQL) join(", ")
        )
        where_clause := ""
        if(condition isNil not,
            where_clause = " WHERE #{ condition getAsSQL(session) }" interpolate
        )
        return("""SELECT #{ field_names } FROM #{ table getNameAsSQL }#{ where_clause };""" interpolate)
    )
)

CreateTable := Object clone do(
    table ::= nil
    
    getAsSQL := method(
        queries := list()
        table fields foreach(field,
            queries append(field getCreateQuery)
        )
        return("""CREATE TABLE #{ table getNameAsSQL } (#{ queries join(", ") });""" interpolate)
    )
)

InsertInto := Object clone do(
    table ::= nil
    fields ::= nil

    getAsSQL := method(
        columns := list()
        values := list()
        fields foreach(field,
            columns append(field getNameAsSQL)
            values append(field getValueAsSQL)
        )
        return(("""INSERT INTO #{ table getNameAsSQL } (#{ columns join(", ") }) """ ..
        """VALUES (#{ values join(", ") });""") interpolate)
    )
)

Update := Object clone do(
    table ::= nil
    fields ::= nil
    condition ::= nil

    getAsSQL := method(
        query := """UPDATE #{ table getNameAsSQL } SET """ interpolate asMutable
        query appendSeq(fields map(field,
            """#{ field getNameAsSQL } = #{ field getValueAsSQL}""" interpolate
        ) join(", "))
        query appendSeq(" WHERE #{ condition getAsSQL(session) }" interpolate)
        query appendSeq(";")
        query
    )
)
