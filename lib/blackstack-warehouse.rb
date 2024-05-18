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
