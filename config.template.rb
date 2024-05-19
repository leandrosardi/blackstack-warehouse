BlackStack::PostgreSQL::set_db_params({
  :db_url => '127.0.0.1',
  :db_port => 5432,
  :db_name => 'demo',
  :db_user => 'blackstack',
  :db_password => '<your database password>',
})

DB = BlackStack::PostgreSQL::connect
