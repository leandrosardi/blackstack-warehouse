require 'blackstack-db'
require 'simple_cloud_logging'
require 'pry'

module BlackStack
    class Warehouse
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

        # Move data from origin to archive.
        # Parameters:
        # - origin: Symbol. Name of the table to take data from. Example: :post. Mandatory.
        # - archive: Symbol. Name of the table to store the data. Example: :post_archive. Default: "#{origin.to_s}_archive".
        # - primary_key: Array of Symbols. Columns of the primary key. Example: [:id]. Default: [:id].
        # - age_field: Symbol. Column to use to calculate the age of the record. Example: :create_time. Default: :create_time.
        # - age_to_archive: Integer. Example: 1 (days). 0 means never archive.
        # - age_to_drain: Integer. Example: 90 (days). 0 means never drain.
        # 
        def self.archive(
            origin: ,
            archive: nil,
            primary_key: :id,
            age_field: :create_time,
            age_to_archive: 1, 
            age_to_drain: 90,
            logger: nil, 
        )
            l = logger || BlackStack::DummyLogger.new(nil)
            archive ||= "#{origin.to_s}_archive"



        end # def self.archive

    end # class Warehouse
end # module BlackStack
