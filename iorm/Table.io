Table := Object clone do(
    session ::= nil
    name ::= nil
    fields ::= nil

    init := method(
        resend
    )

    getNameAsSQL := method(
        /* don't quote, mysql doesn't like it. */
        name
    )

    getFieldByName := method(name,
        fields foreach(field,
            if(field name == name,
                return(field)
            )
        )
        return(nil)
    )

    hasField := method(name,
        getFieldByName(name) isNil not
    )
)
