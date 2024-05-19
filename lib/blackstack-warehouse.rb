require 'blackstack-db'
require 'simple_cloud_logging'

module BlackStack
    class Warehouse
        AGE_UNITS = [:minutes, :hours, :days, :weeks, :months, :years]
        @@tables = []

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
        # - age_units: Symbol. :minutes, :hours, :days, :weeks, :months or :years. Default: :hours.
        # - batch_size: Integer. Number of records to move in each batch. Default: 1000.
        # 
        def self.archive(
            origin: ,
            archive: nil,
            primary_key: :id,
            age_field: :create_time,
            age_to_archive: 1, 
            age_units: :hours, 
            batch_size: 1000,
            logger: nil
        )
            l = logger || BlackStack::DummyLogger.new(nil)
            archive ||= "#{origin.to_s}_archive".to_sym
            err = []

            err << 'origin must be a symbol' unless origin.is_a? Symbol
            err << 'archive must be a symbol' unless archive.is_a? Symbol
            err << 'primary_key must be a symbol' unless primary_key.is_a? Symbol
            err << 'age_field must be a symbol' unless age_field.is_a? Symbol
            err << 'age_to_archive must be an integer' unless age_to_archive.is_a? Integer
            err << 'age_to_archive must be greater than or equal to 0' unless age_to_archive >= 0
            err << "age_units must be #{AGE_UNITS.join(', ')}" unless AGE_UNITS.include? age_units
            err << 'batch_size must be an integer' unless batch_size.is_a? Integer
            err << 'batch_size must be greater than 0' unless batch_size > 0

            raise err.join("\n") unless err.empty?

            # select all records where age is greater than age_to_archive days.
            l.logs 'Insert into the archive... '
            records = DB[origin.to_sym].where(Sequel.lit("
                \"#{age_field.to_s}\" < CAST('#{now}' AS TIMESTAMP) - INTERVAL '#{age_to_archive} #{age_units.to_s}'
            ")).except(DB[archive])
            l.logf 'done'.green + "(#{records.count.to_s.blue} records)"

            # split records in batches of batch_size
            # insert records into archive table.
            i = 0
            batches = records.each_slice(batch_size)
            batches.each { |batch|
                i += 1
                # inserting in the archive table, only if doesn't exist a record with the same key
                l.logs "Inserting batch #{i.to_s} into archive... "
                exists = DB[archive.to_sym].where(primary_key => batch.map { |r| r[primary_key] }).count > 0
                if exists
                    raise "Record(s) already exists in archive table."
                else
                    DB[archive.to_sym].multi_insert(batch)
                    l.logf 'done'.green
                end
            }

            # select all records in the origin that already exist in the archive.
            l.logs 'Delete from the origin... '
            records = DB[origin.to_sym].intersect(DB[archive])
            l.logf 'done'.green + "(#{records.count.to_s.blue} records)"

            # split records in batches of batch_size
            # delete records from origin table.
            i = 0
            batches = records.each_slice(batch_size)
            batches.each { |batch|
                i += 1
                l.logs "Deleting batch #{i.to_s} from origin... "
                DB[origin.to_sym].where(primary_key => batch.map { |r| r[primary_key] }).delete
                l.logf 'done'.green
            }
        end # def self.archive

        # Delete data from the archive permanently.
        # Parameters:
        # - origin: Symbol. Name of the table to take data from. Example: :post. Mandatory.
        # - archive: Symbol. Name of the table to store the data. Example: :post_archive. Default: "#{origin.to_s}_archive".
        # - primary_key: Array of Symbols. Columns of the primary key. Example: [:id]. Default: [:id].
        # - age_field: Symbol. Column to use to calculate the age of the record. Example: :create_time. Default: :create_time.
        # - age_to_drain: Integer. Example: 90 (days). 0 means never drain.
        # - age_units: Symbol. :minutes, :hours, :days, :weeks, :months or :years. Default: :hours.
        # - batch_size: Integer. Number of records to move in each batch. Default: 1000.
        # 
        def self.drain(
            origin: ,
            archive: nil,
            primary_key: :id,
            age_field: :create_time,
            age_to_drain: 90,
            age_units: :hours, 
            batch_size: 1000,
            logger: nil
        )
            l = logger || BlackStack::DummyLogger.new(nil)
            archive ||= "#{origin.to_s}_archive".to_sym
            err = []

            err << 'origin must be a symbol' unless origin.is_a? Symbol
            err << 'archive must be a symbol' unless archive.is_a? Symbol
            err << 'primary_key must be a symbol' unless primary_key.is_a? Symbol
            err << 'age_field must be a symbol' unless age_field.is_a? Symbol
            err << 'age_to_drain must be an integer' unless age_to_drain.is_a? Integer
            err << 'age_to_drain must be greater than or equal to 0' unless age_to_drain >= 0
            err << "age_units must be #{AGE_UNITS.join(', ')}" unless AGE_UNITS.include? age_units
            err << 'batch_size must be an integer' unless batch_size.is_a? Integer
            err << 'batch_size must be greater than 0' unless batch_size > 0

            raise err.join("\n") unless err.empty?

            # select all records where age is greater than age_to_drain days.
            l.logs 'Delete from the archive... '
            records = DB[archive.to_sym].where(Sequel.lit("
                \"#{age_field.to_s}\" < CAST('#{now}' AS TIMESTAMP) - INTERVAL '#{age_to_drain} #{age_units.to_s}'
            "))
            l.logf 'done'.green + "(#{records.count.to_s.blue} records)"

            # split records in batches of batch_size
            # delete records from origin table.
            i = 0
            batches = records.each_slice(batch_size)
            batches.each { |batch|
                i += 1
                l.logs "Deleting batch #{i.to_s} from origin... "
                DB[archive.to_sym].where(primary_key => batch.map { |r| r[primary_key] }).delete
                l.logf 'done'.green
            }
        end # def self.drain

        # Delete data from the archive permanently.
        # Parameters:
        # - origin: Symbol. Name of the table to take data from. Example: :post. Mandatory.
        # - archive: Symbol. Name of the table to store the data. Example: :post_archive. Default: "#{origin.to_s}_archive".
        # - primary_key: Array of Symbols. Columns of the primary key. Example: [:id]. Default: [:id].
        # - age_field: Symbol. Column to use to calculate the age of the record. Example: :create_time. Default: :create_time.
        # - age_to_drain: Integer. Example: 90 (days). 0 means never drain.
        # - age_units: Symbol. :minutes, :hours, :days, :weeks, :months or :years. Default: :hours.
        # - batch_size: Integer. Number of records to move in each batch. Default: 1000.
        # 
        def self.set_one_table(
            origin: ,
            archive: nil,
            primary_key: :id,
            age_field: :create_time,
            age_to_archive: 1,
            age_to_drain: 90,
            age_units: :hours, 
            batch_size: 1000,
            logger: nil
        )
            l = logger || BlackStack::DummyLogger.new(nil)

            archive ||= "#{origin.to_s}_archive".to_sym
            err = []
            err << 'origin must be a symbol' unless origin.is_a? Symbol
            err << 'archive must be a symbol' unless archive.is_a? Symbol
            err << 'primary_key must be a symbol' unless primary_key.is_a? Symbol
            err << 'age_field must be a symbol' unless age_field.is_a? Symbol
            err << 'age_to_drain must be an integer' unless age_to_drain.is_a? Integer
            err << 'age_to_drain must be greater than or equal to 0' unless age_to_drain >= 0
            err << 'age_to_archive must be an integer' unless age_to_archive.is_a? Integer
            err << 'age_to_archive must be greater than or equal to 0' unless age_to_archive >= 0
            err << "age_units must be #{AGE_UNITS.join(', ')}" unless AGE_UNITS.include? age_units
            err << 'batch_size must be an integer' unless batch_size.is_a? Integer
            err << 'batch_size must be greater than 0' unless batch_size > 0

            raise err.join("\n") unless err.empty?

            h = @@tables.find { |t| t[:origin] == origin }
            if h.nil?
                h = {
                    origin: origin,
                    archive: archive,
                    primary_key: primary_key,
                    age_field: age_field,
                    age_to_archive: age_to_archive,
                    age_to_drain: age_to_drain,
                    age_units: age_units,
                    batch_size: batch_size
                }
                @@tables << h
            else
                h[:archive] = archive
                h[:primary_key] = primary_key
                h[:age_field] = age_field
                h[:age_to_archive] = age_to_archive
                h[:age_to_drain] = age_to_drain
                h[:age_units] = age_units
                h[:batch_size] = batch_size
            end

            self.create(
                origin: h[:origin],
                archive: h[:archive] || "#{h[:origin].to_s}_archive".to_sym,
                logger: l
            )
        end # def self.set_one_table

        # set a list of tables to archive and drain.
        def self.set(arr, logger: nil)
            raise "Argument must be an array of hashes" unless arr.is_a? Array
            raise "Argument must be an array of hashes" unless arr.all? { |e| e.is_a? Hash }
            arr.each { |h|
                self.set_one_table(
                    origin: h[:origin],
                    archive: h[:archive] || "#{h[:origin].to_s}_archive".to_sym,
                    primary_key: h[:primary_key] || :id,
                    age_field: h[:age_field] || :create_time,
                    age_to_archive: h[:age_to_archive] || 1,
                    age_to_drain: h[:age_to_drain] || 90,
                    age_units: h[:age_units] || :hours,
                    batch_size: h[:batch_size] || 1000,
                    logger: logger
                )
            }
        end # def self.set

        def self.archive_all(logger:nil)
            @@tables.each { |h|
                self.archive(
                    origin: h[:origin],
                    archive: h[:archive] || "#{h[:origin].to_s}_archive".to_sym,
                    primary_key: h[:primary_key] || :id,
                    age_field: h[:age_field] || :create_time,
                    age_to_archive: h[:age_to_archive] || 1,
                    age_units: h[:age_units] || :hours,
                    batch_size: h[:batch_size] || 1000,
                    logger: logger
                )
            }
        end # def self.archive_all

        def self.drain_all(logger:nil)
            @@tables.each { |h|
                self.drain(
                    origin: h[:origin],
                    archive: h[:archive] || "#{h[:origin].to_s}_archive".to_sym,
                    primary_key: h[:primary_key] || :id,
                    age_field: h[:age_field] || :create_time,
                    age_to_drain: h[:age_to_drain] || 90,
                    age_units: h[:age_units] || :hours,
                    batch_size: h[:batch_size] || 1000,
                    logger: logger
                )
            }
        end # def self.drain_all

    end # class Warehouse
end # module BlackStack
