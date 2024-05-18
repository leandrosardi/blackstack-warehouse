# Initialization: Create and seed a new table.

require 'blackstack-warehouse'
require 'config'

l = BlackStack::LocalLogger.new('./create.log')

BlackStack::Warehouse.create(
    origin: :post,
    logger: l,
)


