MapperError := Exception clone

Model := Object clone do(
    session ::= nil
    fields ::= nil
    primaryKey ::= nil
    meta ::= nil
    tableName ::= nil
    table ::= nil
    instances := nil
    to_be_saved := nil
    objects := nil

    init := method(
        fields = list()
        instances = list()
        to_be_saved = list()
        objects = Iorm ObjectsManager with(self)
    )

    addToBeSaved := method(instance,
        to_be_saved append(WeakLink clone setLink(instance))
        self
    )

    removeToBeSaved := method(instance,
        i := to_be_saved detect(item, item link == instance)
        if(i isNil not,
            to_be_saved remove(i)
        )
        self
    )

    saveAll := method(
        to_be_saved foreach(instance,
            instance link save
        )
        to_be_saved empty
        self
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
        _queryFromSimpleCondition(call message argAt(0))
    )

    _queryFromSimpleCondition := method(msg,
        # parse
        condition := Iorm parseSimpleCondition(table, msg)
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
        # Not existing -> create
        createInstanceFromPrimaryKey(pk)
    )

    createInstanceFromPrimaryKey := method(pk,
        # create and return a new instance of the model
        # retrieve all values from the database
        condition := Iorm constructTree(table, 
            Equals(
                Field(primaryKey),
                Value(pk)
            )
        )
        query := Iorm Select clone setTable(table) setCondition(condition)
        inst := self instance
        inst setAlreadyExisting(true) # <- important
        inst syncFromResult(session query(query))
        inst
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
            self newToBeSavedSlot(field name, field value)
            self fields append(field clone)
        )
    )

    newToBeSavedSlot := method(name, initial,
        setter := "set" .. (name asCapitalized)
        self setSlot(setter,
            doString("""method(new,
                getFieldByName("#{ name }") setValue(new)
                self #{ name } = new
                model addToBeSaved(self); self)""" interpolate)
        )
        self setSlot(name, initial)
        initial
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
        result first # that's important.
        result fields foreach(name,
            field := getFieldByName(name)
            if(field isNil,
                MapperError raise("Unknown field in result: #{ name }" interpolate)
            )
            # set field's value
            field setValueFromSQL(result at(name))
            # and the cached value
            setValueOf(name, field value)
        )
        result done # that's also important.
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
            setValueOf(model primaryKey, model table generateID)
            syncFields
            insert := Iorm InsertInto clone setTable(model table) setFields(fields)
            session executeNow(insert)
            alreadyExisting = true
        ,
            /* now do the UPDATE query */
            condition := Iorm Condition withTable(model table) addFilterCondition(
                    Iorm constructTree(model table,
                        Equals(
                            Field(model primaryKey),
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
        self updateSlot(name, value) 
        # ... ok. if a field is named `name`, leaving the `self` is not a good idea,
        # because the local argument slot will be updated. explicit self, need you.
    )

    getValueAsSQL := method(
        # make it usable for conditions
        getPrimaryKeyField getValueAsSQL
    )
)

ObjectsManager := Object clone do(
    # This query manager manages queries.
    model ::= nil

    all := method(
        model instances
    )

    filter := method(
       model _queryFromSimpleCondition(call message argAt(0))
    )

    with := method(model_,
        c := self clone
        c setModel(model_)
        c
    )
)
