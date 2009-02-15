InvalidValueError := Exception clone

Field := Object clone do(
    typeName ::= "FIELD"
    ioProto ::= Object
    name ::= nil
    value := nil
    table ::= nil
    flags ::= nil

    init := method(
        setFlags(list())
        resend
    )

    getNameAsSQL := method(
        # The name is not quoted. TODO: Fine?
        name
    )

    getFlagsAsSQL := method(
        flags join(" ")
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

    addFlag := method(flag,
        flags append(flag)
    )

    newFlagSetter := method(sql,
        # well, that's an ugly macro. can it be done nicer?
        doString("""method(is, if(is, flags appendIfAbsent("#{ sql }"), flags remove("#{ sql }")); self)""" interpolate)
    )

    setIsPrimaryKey := newFlagSetter("PRIMARY KEY")
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
        """#{ quote(name) } #{ typeName } #{ getFlagsAsSQL }""" interpolate
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
        """#{ quote(name) } #{ typeName }(#{ length }) #{ getFlagsAsSQL }""" interpolate
    )
)
