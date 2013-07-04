dropdb geogossip
createdb geogossip
cat db/create.sql db/triggers.sql | psql geogossip
