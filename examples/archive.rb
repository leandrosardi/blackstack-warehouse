# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./archive.log')

BlackStack::Warehouse.archive(
    origin: :post,
    age_to_archive: 1,
    age_units: :hours,
    logger: l,
)


