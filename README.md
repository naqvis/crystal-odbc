# crystal-odbc

Crystal ODBC driver implements [crystal-db](https://github.com/crystal-lang/crystal-db) API and is a wrapper around [unixODBC](http://www.unixodbc.org).

unixODBC is an open-source ODBC-library that you can run on non-Windows platforms. It is the glue between odbc (this shard) and your SQL driver.

## Version matters! ##
If you want to use odbc with unixODBC make sure you are running unixODBC 2.3.7!

## Installation

1. Make sure you have unixODBC and SQL Driver (ODBC Driver/Connector) installed. Look into DBMS of your choice and find their ODBC driver installation instructions for your system.

2. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     odbc:
       github: naqvis/crystal-odbc
   ```

2. Run `shards install`

## Usage

```crystal
require "db"
require "odbc"

DB.open "odbc://DSN=dsn;UID=user;PWD=password" do |db|
  db.exec "create table contacts (name text, age integer)"
  db.exec "insert into contacts values (?, ?)", "John Doe", 30

  args = [] of DB::Any
  args << "Sarah"
  args << 33
  db.exec "insert into contacts values (?, ?)", args

  puts "max age:"
  puts db.scalar "select max(age) from contacts" # => 33

  puts "contacts:"
  db.query "select name, age from contacts order by age desc" do |rs|
    puts "#{rs.column_name(0)} (#{rs.column_name(1)})"
    # => name (age)
    rs.each do
      puts "#{rs.read(String)} (#{rs.read(Int32)})"
      # => Sarah (33)
      # => John Doe (30)
    end
  end
end
```
refer to [crystal-db](https://github.com/crystal-lang/crystal-db) for further usage instructions.

## Development

To run all tests:

```
crystal spec
```

## Contributing

1. Fork it (<https://github.com/naqvis/crystal-odbc/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
