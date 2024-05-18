# blackstack-warehouse

Automated data archiving into a replicated database schema.

## 1. Installation

```
gem install blackstack-warehouse
```

## 2. Getting Started

```ruby
wh = BlackStack::Warehouse.new(
    :table => :event,
    :primary_key => [:id],
    :age_field => :create_time,
    :age_to_archive => 1, # Integer. Example: 1 (days). 0 means never archive.
    :age_to_drain => 90, # Integer. Example: 90 (days). 0 means never drain.
)

wh.archive
```