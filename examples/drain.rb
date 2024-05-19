# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./drain.log')

l = BlackStack::LocalLogger.new('./archive.log')

BlackStack::Warehouse.set([{
    :origin => :post,
    :primary_key => :id, 
    :age_field => :create_time,
    :age_to_archive => 1,
    :age_to_drain => 90,
    :age_units => :hours,
#}, {
    # TODO: Add more tables here...
}], logger: l)

BlackStack::Warehouse.drain_all(logger: l)

