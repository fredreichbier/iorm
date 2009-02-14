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
            
            save := method(
                sync
                if(alreadyExisting not,
                    /* we have to make an INSERT query first */
                    insert := Iorm InsertInto clone setTable(table) setFields(fields)
                    session executeNow(insert)
                )
                /* now do the UPDATE query */
                update := Iorm Update clone setTable(table) setFields(fields) setCondition(
                    pk := (Message clone fromString(primaryKey))
                    Iorm Condition with(pk == "foo")
                )
                session executeNow(update)
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
)
