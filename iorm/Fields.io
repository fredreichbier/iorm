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
        if(new_value isNil not,
            checkValue(new_value)
        )
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
    setAutoIncrement := newFlagSetter("AUTO INCREMENT")
    setNotNull := newFlagSetter("NOT NULL")
)

IntegerField := Field clone do(
    setTypeName("INTEGER")
    setIoProto(Number)

    getValueAsSQL := method(
        quote(value)
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
        quote(value)
    )

    setValueFromSQL := method(sql,
        self setValue(sql)
    )

    getCreateQuery := method(
        """#{ quote(name) } #{ typeName }(#{ length }) #{ getFlagsAsSQL }""" interpolate
    )
)

OneToManyField := Field clone do(
    reference ::= nil

    getValueAsSQL := method(
        value getPrimaryKeyField getValueAsSQL
    )

    setValueFromSQL := method(sql,
        "setting one to many field from #{ sql }" interpolate println
    )
    
    getCreateQuery := method(
        """#{ quote(name) } #{ reference getPrimaryKeyField typeName }""" interpolate
    )

    checkValue := method(value,
        if(value hasProto(reference) not,
            Iorm InvalidValueError raise("#{ value } is not a #{ reference }" interpolate)
        )
    )

    with := method(reference_,
        c := self clone
        c setReference(reference_)
        c
    )
)
