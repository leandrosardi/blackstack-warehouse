=begin
new_table_name = 'account_archive'

DB.create_table new_table_name.to_sym if DB.table_exists?(new_table_name.to_sym) 

DB.schema(:account).each { |k, col|
    puts k.to_s
    puts col.to_s

    DB.alter_table :account_archive do
        add_column k, col[:db_type]
    end
}

DB.alter_table :account_archive do
    add_column :category, String, default: 'ruby'
end
=end

