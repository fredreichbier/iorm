doRelativeFile("iorm/Iorm.io")

session := Iorm Session withSQLite("./test.sqlite")

Author := Iorm Model with(session) setup(
    setTableName("authors")
    newField("name", Iorm VarcharField clone setLength(50))
)
Author create

Book := Iorm Model with(session) setup(
    setTableName("books")
    newField("author", Iorm OneToManyField with(Author))
    newField("name", Iorm VarcharField clone setLength(50))
)
Book create

max_goldt := Author clone setName("Max Goldt")
qq := Book clone setName("QQ") setAuthor(max_goldt)
max_goldt save
qq save

"Author of #{ qq name } is #{ qq author name }!" interpolate println

session commit
