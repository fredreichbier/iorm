Table := Object clone do(
    session ::= nil
    name ::= nil
    fields ::= nil
    lastID ::= 0

    init := method(
        lastID = 0
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
        lastID = lastID + 1
        lastID
    )

    updateLastID := method(new_id,
        if(new_id > lastID,
            setLastID(new_id)
        )
    )
)
