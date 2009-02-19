# That's a simple example how to use Iorm's models and
# condition features.

# first, we include Iorm.
doRelativeFile("../iorm/Iorm.io")

# then, we create a SQLite session. Currently,
# only SQLite sessions are supported, but since
# Iorm uses the database independent DBI addon,
# it should be easy to use other backends as well.
session := Iorm Session withSQLite("./basic.sqlite")

# We create our first model: The author.
# The model has a reference to the session.
# `model setup(...)` is just a shortcut for
# `model do(...) done`. It is necessary to call
# `done` after all fields are created.
Author := Iorm Model with(session) setup(
    # we set the table name. At the moment, it's not possible
    # to let Iorm autodetect it. But it's planned.
    setTableName("authors")
    # An author has a name. That's a VarcharField with a 
    # maximum length of 50 characters (that's
    # not relevant for SQLite, but we provide it anyway).
    # The value of a VarcharField has to be a Sequence.
    newField("name", Iorm VarcharField clone setLength(50))
)
# Now, after having implicitly called `done`, we create the
# table. If you are using an existing database, you won't
# have to call that, of course.
Author create

# Our second model is a book. A book is connected to an author.
# That's a Many-To-One relation. Fortunately, Iorm does already
# support this kind of relations (yay!).
Book := Iorm Model with(session) setup(
    setTableName("books")
    # A Many-To-One relation is created with the `ForeignKeyField`.
    # `Iorm ForeignKeyField with(Author)` is a shortcut for
    # `Iorm ForeignKeyField clone setReference(Author)`.
    newField("author", Iorm ForeignKeyField with(Author))
    # A book has a title ...
    newField("title", Iorm VarcharField clone setLength(50))
)
# Finally, create the table.
Book create

# Now it's time for some demo records.
# `Author instance` is a shortcut or `Instance clone setModel(Author)`.
max_goldt := Author instance
# You can access the model fields like normal Io attributes.
max_goldt setName("Max Goldt")
# And that would also work: `name := max_goldt name`.
# He has put together some books, of course. We'll add two of them.
qq := Book instance setTitle("QQ") 
# That's the interesting part. You can set the author reference just
# as you would set any other value!
qq setAuthor(max_goldt)
# Another book!
mind_boggling := Book instance setTitle("Mind-boggling") setAuthor(max_goldt)
# Normally, we would have to call `save` on each created and changed instance.
# But we're lazy, and we'll just call the model's `saveAll`. 
# That will do the same.
Author saveAll
Book saveAll

# And if you want to receive all books by Max Goldt now, you will just call ...
books := Book objects filter(author == max_goldt)
# ... and you get a list of `Instance` clones.
"Max Goldt wrote:" println
books foreach(book,
    (" * " .. book title) println
)
# Or if you want to get all books named "QQ" (there is only one, indeed) you'll call:
books_named_qq := Book objects filter(title == "QQ")
books_named_qq foreach(book,
    "'#{ book title }' is named 'QQ'!" interpolate println
)
# That's it. If you have any questions, suggestions, whatever, feel free to contact me:
# http://github.com/fredreichbier
