# blackstack-warehouse

Automated data archiving into a replicated database schema.

## 1. Installation

```
gem install blackstack-warehouse
```

## 2. Getting Started

Use [BlackStack DB](https://github.com/leandrosardi/blackstack-db) to setup your database connection.

```ruby
BlackStack::PostgreSQL::set_db_params({
  :db_url => '127.0.0.1',
  :db_port => 5432,
  :db_name => 'demo',
  :db_user => 'blackstack',
  :db_password => 'SantaClara123',
})
```

Connect the database too.

```ruby
DB = BlackStack::PostgreSQL::connect
```

Use [BlackStack WareHouse]() for automatically: 

1. create **archivement tables**; and
2. move data from **original tables** to **archivement tables**.

```ruby
wh = BlackStack::Warehouse.new(
    :table => :event,
    :primary_key => [:id],
    :age_field => :create_time,
    # Integer. Example: 1 (days). 0 means never archive.
    :age_to_archive => 1,
    # Integer. Example: 90 (days). 0 means never drain. 
    :age_to_drain => 90, 
)

wh.archive
```