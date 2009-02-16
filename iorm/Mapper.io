MapperError := Exception clone

Model := Object clone do(
    session ::= nil
    fields ::= nil
    primaryKey ::= nil
    meta ::= nil
    tableName ::= nil
    table ::= nil
    alreadyExisting ::= false

    init := method(
        fields = list()

        self do(
            /* cloning a Model clone means: create a record. */
            init := method(
                /* create a slot for each field */
                self fields = fields clone
                fields foreach(field,
                    self newSlot(field name, field value)
                )
                /* setup the table stuff */
                if(isNil(meta) not,
                    /* has meta information */
                    1
                )
            )

            syncFromResult := method(result,
                result fields foreach(name,
                    field := getFieldByName(name)
                    if(field isNil,
                        MapperError raise("Unknown field in result: #{ name }" interpolate)
                    )
                    field setValueFromSQL(result at(name))
                )
                    self
            )

            /* set all fields' values to the actually used values */
            syncFields := method(
                fields foreach(field,
                    field setValue(self getSlot(field name)) # TODO: Validation?
                )
            )

            getFieldByName := method(name,
                fields foreach(field,
                    if(field name == name,
                        return(field)
                    )
                )
                nil
            )

            getPrimaryKeyField := method(
                getFieldByName(primaryKey)
            )
            
            save := method(
                if(alreadyExisting not,
                    /* we have to make INSERT query first */
                    syncFields
                    insert := Iorm InsertInto clone setTable(table) setFields(fields)
                    session executeNow(insert)
                    alreadyExisting = true
                ,
                    /* now do the UPDATE query */
                    condition := Iorm Condition withTable(table) addFilterCondition(
                            Iorm constructTree(table,
                                Equals(
                                    Field(primaryKey),
                                    Value(getFieldByName(primaryKey) value)
                                )
                            )
                    )
                    # TODO: can the primary key be updated? No, i think
                    syncFields
                    update := Iorm Update clone setTable(table) setFields(fields) setCondition(
                        condition
                    )
                    session executeNow(update)
                )
                self
            )
        )
    )

    done := method(
        # add an implicit primary key if none explicitly defined
        if(primaryKey isNil,
            # XXX: we mustn't use auto increment, otherwise sqlite won't do any
            # auto incrementing. straaaaaange.
            f := Iorm IntegerField clone setAutoIncrement(false)
            f setIsPrimaryKey(true)
            f setName("pk")
            fields prepend(f)
            setPrimaryKey("pk")
        )
        table = Iorm Table clone # TODO: ARGH!
        table setSession(session) setName(tableName) setFields(fields)
        self
    )

    newField := method(name, field,
        field setName(name)
        fields append(field)
        self
    )

    create := method(
        query := Iorm CreateTable clone setTable(table)
        session executeDeferred(query)
        self
    )

    assignField := method(
        name println
        pr println
    )

    setup := method(
        stuff := call message argAt(0)
        stuff doInContext(self)
        done
        self
    )

    with := method(session,
        c := self clone
        c setSession(session)
        c
    )
)
