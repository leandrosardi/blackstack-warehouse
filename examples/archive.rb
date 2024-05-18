# Initialization: Create and seed a new table.

require 'blackstack-db'
require 'simple_cloud_logging'

l = BlackStack::LocalLogger.new('./archive.log')

l.logs 'Setup database connection... '
BlackStack::PostgreSQL::set_db_params({
  :db_url => '127.0.0.1',
  :db_port => 5432,
  :db_name => 'demo',
  :db_user => 'blackstack',
  :db_password => 'SantaClara123',
})
l.logf 'done'.green

l.logs 'Connecting the database... '
DB = BlackStack::PostgreSQL::connect
l.logf 'done'.green

l.logs 'Creating archivement table... '
new_table_name = 'post_archive'
DB.create_table new_table_name.to_sym if !DB.table_exists?(new_table_name.to_sym) 
l.logf 'done'.green

l.logs 'Adding columns... '
DB.schema(:post).each { |k, col|
    puts k.to_s
    puts col.to_s

    DB.alter_table :post_archive do
        add_column k, col[:db_type]
    end
}
l.logf 'done'.green