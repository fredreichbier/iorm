ConditionError := Exception clone

parseSimpleCondition := method(msg, context,
    if(context isNil,
        context = thisContext
    )
    one := msg clone setNext(nil) asString
    field := Iorm Condition Field with(one)
    op := msg next name
    two := msg next argAt(0) doInContext(context)
    value := Iorm Condition Value with(two)
    node := op switch(
        "==",
            Iorm Condition Equals with(field, value),
        "!=",
            Iorm Condition Differs with(field, value),
        ">",
            Iorm Condition GreaterThan with(field, value),
        "<",
            Iorm Condition LessThan with(field, value)
    )
    if(node isNil,
        ConditionError raise("No appropriate SQL operator found for '#{ op }'" interpolate)
    )
    node
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
            children map(getAsSQL(session)) join(" #{ operator } " interpolate)
        )
    )

    Equals := BinaryOperator clone setOperator("=")
    Differs := BinaryOperator clone setOperator("!=")
    GreaterThan := BinaryOperator clone setOperator(">")
    LessThan := BinaryOperator clone setOperator("<")
    And := BinaryOperator clone setOperator("AND")
)

