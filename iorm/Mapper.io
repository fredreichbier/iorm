MapperError := Exception clone

Model := Object clone do(
    session ::= nil
    fields ::= nil
    primaryKey ::= nil
    meta ::= nil
    tableName ::= nil
    table ::= nil
    instances := nil

    init := method(
        fields = list()
        instances = list()
    )

    done := method(
        # add an implicit primary key if none explicitly defined
        if(primaryKey isNil,
            f := Iorm IntegerField clone
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

    queryFromSimpleCondition := method(
        # parse
        condition := Iorm parseSimpleCondition(table, call message argAt(0))
        # make query
        query := Iorm Select clone setTable(table) setCondition(condition)
        query setFields(list(getPrimaryKeyField))
        # query
        result := session query(query)
        # objectify results
        results := list()
        result foreach(res,
            results append(getInstanceFromPrimaryKey(res at(primaryKey)))
        )
        results
    )

    with := method(session,
        c := self clone
        c setSession(session)
        c
    )

    registerInstance := method(instance,
        instances append(instance)
        self
    )

    getInstanceFromPrimaryKey := method(pk,
        instances foreach(instance,
            if(instance getSlot(primaryKey) == pk,
                return(instance)
            )
        )
        return(nil)
    )

    getFieldByName := method(name,
        fields foreach(field,
            if(field name == name,
                return(field)
            )
        )
        nil
    )

    instance := method(
        Iorm Instance with(self)
    )

    getPrimaryKeyField := method(
        getFieldByName(primaryKey)
    )
)

Instance := Object clone do(
    fields ::= nil
    model := nil
    alreadyExisting ::= false

    setModel := method(new_model,
        model = new_model
        model registerInstance(self)
        model fields foreach(field,
            self newSlot(field name, field value)
            self fields append(field clone)
        )
        setValueOf(model primaryKey, model table generateID)
    )

    init := method(
        # create a slot for each field
        fields = list()
        # setup the table stuff
        if(isNil(meta) not,
            # has meta information
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

    save := method(
        if(alreadyExisting not,
            /* we have to make INSERT query first */
            syncFields
            insert := Iorm InsertInto clone setTable(model table) setFields(fields)
            session executeNow(insert)
            alreadyExisting = true
        ,
            /* now do the UPDATE query */
            condition := Iorm Condition withTable(model table) addFilterCondition(
                    Iorm constructTree(model table,
                        Equals(
                            Field(primaryKey),
                            Value(getFieldByName(model primaryKey) value)
                        )
                    )
            )
            # TODO: can the primary key be updated? No, i think
            syncFields
            update := Iorm Update clone setTable(model table) setFields(fields) setCondition(
                condition
            )
            session executeNow(update)
        )
        self
    )

    with := method(model,
        c := self clone
        c setModel(model)
        c
    )

    getPrimaryKeyField := method(
        getFieldByName(model primaryKey)
    )

    isInstanceOf := method(qmodel,
        qmodel == model
    )

    setValueOf := method(name, value,
        updateSlot(name, value)
    )

    getValueAsSQL := method(
        # make it usable for conditions
        getPrimaryKeyField getValueAsSQL
    )
)
