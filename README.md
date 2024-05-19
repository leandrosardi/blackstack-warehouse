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

Use [BlackStack WareHouse](https://github.com/leandrosardi/blackstack-warehouse) for automatically: 

1. create **archivement tables**; 
2. move aged data from **original tables** to **archivement tables**;
3. permanently delete (draining) of too aged data.

**Archivement Tables:**

```ruby
BlackStack::Warehouse.set([{
    :origin => :post,
    :primary_key => :id, 
    :age_field => :create_time,
    :age_to_archive => 1,
    :age_to_drain => 90,
    :age_units => :hours,
#}, {
    # TODO: Add more tables here...
}])
```

**Archivement:**

```ruby
BlackStack::Warehouse.archive_all
```

**Draining:**

```ruby
BlackStack::Warehouse.drain_all
```

## 2. Logging

Create a logger to track the internal work.

```ruby
l = BlackStack::LocalLogger.new('./foo.log')
```

**Archivement:**

```ruby
BlackStack::Warehouse.archive_all(logger: l)
```

**Draining:**

```ruby
BlackStack::Warehouse.drain_all(logger: l)
```

## 3. Parameters

| Name           | Type    | Description                                                                       | Default Value                      |
|----------------|---------|-----------------------------------------------------------------------------------|------------------------------------|
| origin         | Symbol  | Name of the table to take data from.                                              | Mandatory.                         |
| archive        | Symbol  | Name of the table to store the archived data.                                              | Default: "#{origin.to_s}_archive". |
| primary_key    | Symbol  | Name of the primary key column.                                                   | Default: [:id].                    |
| age_field      | Symbol  | Column to use to calculate the age of the record.                                 | Default: :create_time.             |
| age_to_archive | Integer | Number of hours, days, weeks, months or years to wait a record before archive it. | Default: 1.                        |
| age_to_drain   | Integer | Number of hours, days, weeks, months or years to wait a record before archive it. | Default: 90.                       |
| age_units      | Symbol  | :minutes, :hours, :days, :weeks, :months or :years.                               | Default: :hours.                   |
| batch_size     | Integer | Number of records to move in each batch.                                          | Default: 1000.                     |