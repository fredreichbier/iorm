doRelativeFile("iorm/Iorm.io")

session := Iorm Session withSQLite("./test.sqlite")

Author := Iorm Model with(session) setup(
    setTableName("authors")
    newField("name", Iorm VarcharField clone setLength(50))
)
Author create

Book := Iorm Model with(session) setup(
    setTableName("books")
    newField("author", Iorm ForeignKeyField with(Author))
    newField("name", Iorm VarcharField clone setLength(50))
)
Book create

max_goldt := Author instance setName("Max Goldt")
qq := Book instance setName("QQ") setAuthor(max_goldt)
mind_boggling := Book instance setName("Mind-boggling") setAuthor(max_goldt)

Author saveAll
Book saveAll

Author queryFromSimpleCondition(name == "Max Goldt") println

books := Book queryFromSimpleCondition(author == max_goldt)
"Max Goldt wrote:" println
books foreach(book,
    (" * " .. book name) println
)

session commit
