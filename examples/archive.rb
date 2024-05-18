# Initialization: Create and seed a new table.

require 'blackstack-db'
require 'simple_cloud_logging'
require 'pry'

module BlackStack
    module Warehouse
        def self.create(
            origin: , # table name from where I will get the database
            archive: nil, # table name where I will store the database 
            logger: nil
        )
            archive ||= "#{origin.to_s}_archive"
            l = logger || BlackStack::DummyLogger.new(nil)
            
            l.logs 'Creating archivement table... '
            if DB.table_exists?(archive)
                l.logf 'already exists'.yellow
            else
                DB.create_table archive.to_sym  
                l.logf 'done'.green
            end
            
            l.logs 'Adding columns... '
            DB.schema(origin.to_sym).each { |k, col|
                l.logs "Adding column: #{k.to_s.blue}... "
                begin
                    DB.alter_table archive.to_sym do
                        add_column k, col[:db_type]
                    end
                    l.logf 'done'.green
                rescue => e
                    l.logf 'skipped'.yellow #+ " (error: #{e.message})"
                end
            }
            l.logf 'done'.green

        end # def self.create
    end # module Warehouse
end # module BlackStack


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

BlackStack::Warehouse.create(
    origin: :post,
    logger: l,
)


