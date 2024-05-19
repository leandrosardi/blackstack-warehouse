Gem::Specification.new do |s|
    s.name        = 'blackstack-warehouse'
    s.version     = '1.0.1'
    s.date        = '2024-05-19'
    s.summary     = "Implement Data Retention Terms in your SaaS, easily."
    s.description = "Implement Data Retention Terms in your SaaS, easily. BlackStack Warehouse perofrms data archiving into a replicated database schema automatically: https://github.com/leandrosardi/blackstack-warehouse."
    s.authors     = ["Leandro Daniel Sardi"]
    s.email       = 'leandro@connectionsphere.com'
    s.files       = [
      "lib/blackstack-warehouse.rb",
    ]
    s.homepage    = 'https://rubygems.org/gems/blackstack-warehouse'
    s.license     = 'MIT'
    s.add_runtime_dependency 'blackstack-db', '~> 1.0.9', '>= 1.0.9'
    s.add_runtime_dependency 'simple_cloud_logging', '~> 1.2.2', '>= 1.2.2'
  end