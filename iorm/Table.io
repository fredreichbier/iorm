Table := Object clone do(
    session ::= nil
    name ::= nil
    fields ::= nil
    last_id ::= 0

    init := method(
        last_id = 0
        resend
    )

    getNameAsSQL := method(
        session quote(name)
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

    generateID := method(
        # first ID is 1
        last_id = last_id + 1
        last_id
    )
)
