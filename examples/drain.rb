# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./drain.log')

BlackStack::Warehouse.drain(
    origin: :post,
    age_to_drain: 1,
    age_units: :hours,
    logger: l,
)


