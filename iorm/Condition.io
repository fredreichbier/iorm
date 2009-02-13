ConditionError := Exception clone

onlyMessage := method(msg,
    msg clone setNext(nil)
)

parseMessage := method(table, msg,
    subject := msg name
    if(subject == "") then( 
        /* it is empty. that means that's an expression inside parens */
        expr := ("(" .. msg arguments map(arg, parseMessage(table, arg)) join(" ") .. ")") asMutable
        n := msg next
        while(n isNil not,
            expr appendSeq(parseMessage(table, n))
            n = n next
        )
        return(expr)
    ) elseif(OperatorTable operators hasKey(subject)) then(
        /* do an Io operator -> SQL operator conversion */
        ret := subject switch(
            "==",
                " = #{ parseMessage(table, msg argAt(0)) }" interpolate,
            "and",
                " AND (#{ parseMessage(table, msg argAt(0)) })" interpolate
            "or",
                " OR (#{ parseMessage(table, msg argAt(0)) })" interpolate        
        )
        if(ret isNil,
            ConditionError raise("Unwrapped operator: #{ subject }" interpolate)
        )
        return(ret)
    ) elseif(table hasField(subject) not) then(
        /* is an Io object. subsitute. */
        expr := table session quote(onlyMessage(msg) doInContext(call sender) asSimpleString asSymbol) asMutable
        n := msg next
        while(n isNil not,
            expr appendSeq(parseMessage(table, n))
            n = n next
        )
        return(expr)    
    ) else(
        /* is a table field. keep (That is NOT quoted). */
        expr := onlyMessage(msg) asSimpleString asMutable
        n := msg next
        while(n isNil not,
            expr appendSeq(parseMessage(table, n))
            n = n next
        )
        return(expr)
    )
)

parseCondition := method(table,
    parseMessage(table, call message argAt(1))
)

Condition := Object clone do(
    expression := nil
    table ::= nil

    getAsSQL := method(session,
        Iorm parseMessage(table, expression)
    )

    setExpression := method(
        expression = call message argAt(0)
        self
    )
)

