ConditionError := Exception clone

isOperator := method(name,
    OperatorTable operators hasKey(name)
)

_Helper := Object clone do(
    current ::= nil
)

_parseSimpleCondition := method(left, msg, context,
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
            next := m next
            m setNext(nil)
            if(next isNil,
                Iorm Condition Value with(m doInContext(context))
            ,
                _parseSimpleCondition(
                    Iorm Condition Field with(m asString),
                    next,
                    context
                )
            )
        )
        # Now determine which operator we have and convert it to a Condition object.
        # If no operator matches, raise an error.
        node := op switch(
            "==",
                Iorm Condition Equals with(left, value),
            "!=",
                Iorm Condition Differs with(left, value),
            ">",
                Iorm Condition GreaterThan with(left, value),
            "<",
                Iorm Condition LessThan with(left, value),
            "and",
                Iorm Condition And with(left, value),
            "or",
                Iorm Condition Or with(left, value)
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
                node = _parseSimpleCondition(node, current, context)
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

parseSimpleCondition := method(msg, context,
    # The first operand is always a field.
    field := Iorm Condition Field with(msg clone setNext(nil) asString)
    if(msg next isNil,
        field
    ,
        _parseSimpleCondition(field, msg next, context)
    )
)

parseSimple := method(
    msg := call message argAt(0)
    context := call message argAt(1) ifNilEval(thisContext)
    parseSimpleCondition(msg, context)
)

Condition := Object clone do(
    children ::= nil

    init := method(
        children = list()
        resend
    )

    getAsSQL := method(session,
        children map(getAsSQL(session)) join(" AND ") # right?
    )

    addChild := method(child,
        children append(child)
        self
    )

    addFilterCondition := method(condition,
        addChild(condition) # if we use AND to join the conditions, that's ok
        self
    )

    filter := method(
        # for the lazy ones
        addFilterCondition(Iorm parseSimpleCondition(call message argAt(0)))
        self
    )

    with := method(
        c := self clone
        call evalArgs foreach(child, c addChild(child))
        c
    )

    Value := clone do(
        value ::= nil

        getAsSQL := method(session,
            session quote(value asString asSymbol)
        )

        with := method(value,
            c := self clone
            c setValue(value)
            c
        )
    )

    Field := clone do(
        name ::= nil

        getAsSQL := method(session,
            name
        )

        with := method(name,
            c := self clone
            c setName(name)
            c
        )
    )

    BinaryOperator := clone do(
        operator ::= nil

        getAsSQL := method(session,
            "(" .. children map(getAsSQL(session)) join(" #{ operator } " interpolate) .. ")"
        )
    )

    Equals := BinaryOperator clone setOperator("=")
    Differs := BinaryOperator clone setOperator("!=")
    GreaterThan := BinaryOperator clone setOperator(">")
    LessThan := BinaryOperator clone setOperator("<")
    And := BinaryOperator clone setOperator("AND")
    Or := BinaryOperator clone setOperator("OR")
)

