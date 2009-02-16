ConditionError := Exception clone

isOperator := method(name,
    OperatorTable operators hasKey(name)
)

_Helper := Object clone do(
    current ::= nil
)

_parseSimpleCondition := method(table, left, msg, context,
    if(context isNil,
        context = thisContext
    )
    if(Iorm isOperator(msg name)) then(
        # an operator! TODO: differ unary and binary operators (unary have precedence 0?)
        # The current message is the operator.
        op := msg name
        # The first argument of the operator message is the second operand - always a value.
        value := (
            m := msg argAt(0) clone
            # if there is a bracket, use the first argument. TODO: correct?
            while(m name == "",
                m = m argAt(0)
            )
            next := m next
            m setNext(nil)
            if(next isNil,
                Iorm Condition Value with(table, m doInContext(context))
            ,
                _parseSimpleCondition(
                    table,
                    Iorm Condition Field with(table, m asString),
                    next,
                    context
                )
            )
        )
        # Now determine which operator we have and convert it to a Condition object.
        # If no operator matches, raise an error.
        node := op switch(
            "==",
                Iorm Condition Equals with(table, left, value),
            "!=",
                Iorm Condition Differs with(table, left, value),
            ">",
                Iorm Condition GreaterThan with(table, left, value),
            "<",
                Iorm Condition LessThan with(table, left, value),
            "and",
                Iorm Condition And with(table, left, value),
            "or",
                Iorm Condition Or with(table, left, value)
        )
        if(node isNil,
            ConditionError raise("No appropriate SQL operator found for '#{ op }'" interpolate)
        )
        # Now, process any further message on the right side recursively and append them to the
        # current node.
        current := msg next
        while(current isNil not,
            # That's very ugly, but clean. It ensures that we handle a message only once.
            # TODO: Maybe we could use cached results for that?
            if(current hasSlot("_condition_handled") not,
                node = _parseSimpleCondition(table, node, current clone setNext(nil), context)
                current _condition_handled := true
            )
            current = current next
        )
        # ... return the node.
        return(node)
    ) else(
        # is an ordinary message. evaluate.
        return(msg doInContext(context))
    )
)

parseSimpleCondition := method(table, msg, context,
    # Ugly hack, but seems to be needed because messages are not parsed
    # properly if inside parens (a == 3 instead of a ==(3)). Why?
    msg = Message fromString(msg asString)
    # The first operand is always a field.
    field := Iorm Condition Field with(table, msg clone setNext(nil) asString)
    if(msg next isNil,
        field
    ,
        _parseSimpleCondition(table, field, msg next, context)
    )
)

parseSimple := method(table,
    msg := call message argAt(1)
    context := call message argAt(2) ifNilEval(thisContext)
    parseSimpleCondition(table, msg, context)
)

_constructTree := method(table, msg, context,
    name := msg name
    if(Iorm Condition hasSlot(name),
        arguments := msg arguments map(a, _constructTree(table, a, context))
        arguments prepend(table)
        prot := Iorm Condition getSlot(name)
        prot performWithArgList("with", arguments)
    ,
        msg doInContext(context)
    )
)

constructTree := method(table,
    msg := call message argAt(1)
    _constructTree(table, msg, call sender)
)

Condition := Object clone do(
    table ::= nil
    children ::= nil

    init := method(
        children = list()
        resend
    )

    _quote := method(n,
        table session quote(n)
    )

    getAsSQL := method(
        children map(getAsSQL) join(" AND ") # right?
    )

    addChild := method(child,
        children append(child)
        self
    )

    addChildren := method(
        call evalArgs foreach(child, addChild(child))
        self
    )

    addFilterCondition := method(condition,
        addChild(condition) # if we use AND to join the conditions, that's ok
        self
    )

    filter := method(
        # for the lazy ones
        addFilterCondition(Iorm parseSimpleCondition(table, call message argAt(0)))
        self
    )

    with := method(table,
        c := self withTable(table)
        for(i, 1, call argCount - 1,
            c addChild(call evalArgAt(i))
        )
        c
    )

    withTable := method(table,
        c := self clone
        c setTable(table)
        c
    )

    Value := clone do(
        value ::= nil

        getAsSQL := method(
            # allow fields or instances as values
            if(value hasSlot("getValueAsSQL"),
                value getValueAsSQL
            ,
                _quote(value asString asSymbol)
            )
        )

        with := method(table, value,
            c := self withTable(table)
            c setValue(value)
            c
        )
    )

    Field := clone do(
        name ::= nil

        getAsSQL := method(
            name
        )

        with := method(table, name,
            c := self withTable(table)
            c setName(name)
            c
        )
    )

    BinaryOperator := clone do(
        operator ::= nil

        getAsSQL := method(
            "(" .. children map(getAsSQL) join(" #{ operator } " interpolate) .. ")"
        )
    )

    Equals := BinaryOperator clone setOperator("=")
    Differs := BinaryOperator clone setOperator("!=")
    GreaterThan := BinaryOperator clone setOperator(">")
    LessThan := BinaryOperator clone setOperator("<")
    And := BinaryOperator clone setOperator("AND")
    Or := BinaryOperator clone setOperator("OR")
)

