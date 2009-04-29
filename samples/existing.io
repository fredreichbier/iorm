# Now we'll see how Iorm operates with existing tables.
doRelativeFile("../iorm/Iorm.io")
# We use the same models as in `basic.io`.
session := Iorm Session withSQLite("./existing.sqlite")

Author := Iorm Model with(session) setup(
    setTableName("authors")
    newField("name", Iorm VarcharField clone setLength(50))
    newField("info", Iorm TextField clone)
)
# No `Author create` ...

Book := Iorm Model with(session) setup(
    setTableName("books")
    newField("author", Iorm ForeignKeyField with(Author))
    newField("title", Iorm VarcharField clone setLength(50))
)
# ... and no `Book create` - they're already existing!

Author fetchAll
Author objects all println

# Now do a query
max_goldt := Author objects filter(name == "Max Goldt") at(0)
max_goldt info println
