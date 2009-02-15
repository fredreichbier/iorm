Sugar := Object clone do(
    addFieldSyntax := method(
        # does not work. Don't know why :)
        OperatorTable addAssignOperator("->", "assignField")
        self
    )
)
