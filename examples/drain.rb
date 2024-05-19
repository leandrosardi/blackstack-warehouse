# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./drain.log')

l = BlackStack::LocalLogger.new('./archive.log')

BlackStack::Warehouse.set([{
    :origin => :post,
    :age_to_archive => 1,
    :age_to_drain => 90,
    :age_units => :hours,
    :logger => l,
#}, {
    # TODO: Add more tables here...
}
])

BlackStack::Warehouse.drain_all(logger: l)

