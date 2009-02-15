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
                fields foreach(field,
                    self newSlot(field name, field value)
                )
                /* setup the table stuff */
                if(isNil(meta) not,
                    /* has meta information */
                    1
                )
            )

            /* set all fields' values to the actually used values */
            sync := method(
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
            )
            
            save := method(
                if(alreadyExisting not,
                    /* we have to make INSERT query first */
                    sync
                    insert := Iorm InsertInto clone setTable(table) setFields(fields)
                    session executeNow(insert)
                    alreadyExisting = true
                ,
                    /* now do the UPDATE query */
                    condition := Iorm Condition withTable(table) addFilterCondition(
                            Iorm Condition Equals withTable(table) addChildren(
                                Iorm Condition Field with(table,
                                    primaryKey
                                ),
                                Iorm Condition Value with(table,
                                    getFieldByName(primaryKey) value
                                )
                            )
                    )
                    # TODO: can the primary key be updated? No, i think
                    sync
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
)
