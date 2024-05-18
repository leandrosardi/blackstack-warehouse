# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./init.log')

l.logs 'Creating table... '
if DB.table_exists?(:post)
    l.logf 'already exists'.yellow
else
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