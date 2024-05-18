require 'blackstack-db'
require 'simple_cloud_logging'

l = BlackStack::LocalLogger.new('./example.log')
drop_table_if_exists = false

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

l.logs 'Creating table... '
if DB.table_exists?(:post) && !drop_table_if_exists
    l.logf 'already exists'.yellow
else
    DB.drop_table(:post) if drop_table_if_exists

    DB.create_table :post do
        column :id, :uuid, :primary_key => true
        column :create_time, :timestamp, :required => true
        column :title, :varchar, :size => 255, :required => true
    end # create_table
    l.logf 'done'.green
end

i = 0
while i < 60
    i += 1
    l.logs "Inserting data #{i}... "
    DB[:post].insert(:id => guid, :create_time => now, :title => 'Hello, world!')
    sleep 1
    l.logf 'done'.green
end