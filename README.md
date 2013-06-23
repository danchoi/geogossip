# geogossip

## Setup

Create the database

    createdb geogossip
    psql geogossip < db/create.sql
    psql geogossip < db/triggers.sql

Run the Sintra app

    rackup -s thin

Open the app on localhost:9292

![readme](./img/geogossip.png)



