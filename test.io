doRelativeFile("iorm/Iorm.io")

session := Iorm Session withSQLite("./test.sqlite")

Foo := Iorm Model clone do(
    setTableName("Foo")
    newField("integer", Iorm IntegerField clone)
    newField("string", Iorm VarcharField clone setLength(50))
    setPrimaryKey("integer")
) setSession(session)

Foo done create

foo := Foo clone setInteger(123) setString("Hello World!") save

cond := Iorm Condition with(integer == 123)
qry := Iorm Select clone setTable(Foo table) setCondition(cond)

session query(qry) foreach(rec,
    rec at("integer") println
    rec at("string") println
)