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

max_goldt save
qq save
mind_boggling save

#"Author of #{ qq name } is #{ qq author name }!" interpolate println

Author queryFromSimpleCondition(name == "Max Goldt") println

"Found:" println
Book queryFromSimpleCondition(author == max_goldt) foreach(book,
    (" * " .. book name) println
)

session commit
