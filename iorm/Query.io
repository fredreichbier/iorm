Query := Object clone do(
    getAsSQL := method(session,
        ""
    )
)

Select := Object clone do(
    table ::= nil
    fields ::= nil 
    condition := nil

    getAsSQL := method(session,
        field_names := nil
        if(fields isNil,
            field_names = "*"
        ,
            field_names = fields map(f, f getNameAsSQL) join(", ")
        )
        where_clause := ""
        if(condition isNil not,
            where_clause = " WHERE #{ condition getAsSQL }" interpolate
        )
        return("""SELECT #{ field_names } FROM #{ table getNameAsSQL }#{ where_clause };""" interpolate)
    )

    setCondition := method(new_condition,
        if(new_condition table isNil,
            new_condition setTable(table)
        )
        condition = new_condition
        self
    )
)

CreateTable := Object clone do(
    table ::= nil
    
    getAsSQL := method(session,
        queries := list()
        table fields foreach(field,
            queries append(field getCreateQuery)
        )
        return("""CREATE TABLE #{ table getNameAsSQL } ( #{ queries join(", \n") } );""" interpolate)
    )
)

InsertInto := Object clone do(
    table ::= nil
    fields ::= nil

    getAsSQL := method(session,
        columns := list()
        values := list()
        fields foreach(field,
            columns append(field getNameAsSQL)
            values append(field getValueAsSQL)
        )
        return(("""INSERT INTO #{ table getNameAsSQL } (#{ columns join(",") }) """ ..
        """VALUES (#{ values join(",") });""") interpolate)
    )
)

Update := Object clone do(
    table ::= nil
    fields ::= nil
    condition := nil

    getAsSQL := method(session,
        query := """UPDATE #{ table getNameAsSQL } SET """ interpolate asMutable
        query appendSeq(fields map(field,
            """#{ field getNameAsSQL } = #{ field getValueAsSQL} """ interpolate
        ) join(", "))
        query appendSeq(condition getAsSQL)
        query appendSeq(";")
        query println
        query
    )

    setCondition := method(new_condition,
        if(new_condition table isNil,
            new_condition setTable(table)
        )
        condition = new_condition
        self
    )
)
