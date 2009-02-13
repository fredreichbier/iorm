InvalidValueError := Exception clone

Field := Object clone do(
    typeName ::= "FIELD"
    ioProto ::= Object
    name ::= nil
    value := nil
    table ::= nil

    getNameAsSQL := method(
        quote(name)
    )
    
    quote := method(value,
        table session quote(value)
    )

    setValue := method(new_value,
        checkValue(new_value)
        value = new_value
    )

    checkValue := method(new_value,
        if(new_value hasProto(ioProto) not,
            Iorm InvalidValueError raise("#{ new_value } is not a #{ ioProto type }" interpolate)
        )
    )
)

IntegerField := Field clone do(
    setTypeName("INTEGER")
    setIoProto(Number)

    getValueAsSQL := method(
        quote(value asString asSymbol)
    )

    setValueFromSQL := method(sql,
        self setValue(sql asNumber)
    )

    getCreateQuery := method(
        """#{ quote(name) } #{ quote(typeName) }""" interpolate // TODO: `NOT NULL ...`
    )
)

VarcharField := Field clone do(
    setTypeName("VARCHAR")
    setIoProto(Sequence)
    length ::= 50

    getValueAsSQL := method(
        quote(value asSymbol)
    )

    setValueFromSQL := method(sql,
        self setValue(sql)
    )

    getCreateQuery := method(
        """#{ quote(name) } #{ quote(typeName) }(#{ length })""" interpolate // TODO: `NOT NULL ...`
    )
)
