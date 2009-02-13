Table := Object clone do(
    session ::= nil
    name ::= nil
    fields ::= nil

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
)
