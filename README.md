# crystal-odbc

Crystal ODBC driver implements [crystal-db](https://github.com/crystal-lang/crystal-db) API and is a wrapper around [unixODBC](http://www.unixodbc.org).

unixODBC is an open-source ODBC-library that you can run on non-Windows platforms. It is the glue between odbc (this shard) and your SQL driver.

## Version matters!

If you want to use odbc with unixODBC make sure you are running unixODBC 2.3.7!

## Installation

1. Install unixODBC and your database's ODBC driver:

   **Ubuntu/Debian:**

   ```bash
   sudo apt-get install unixodbc unixodbc-dev
   # For SQLite: sudo apt-get install libsqliteodbc
   # For MSSQL: sudo apt-get install msodbcsql17
   # For Oracle: Download from Oracle website
   ```

   **macOS:**

   ```bash
   brew install unixodbc
   # For SQLite: brew install sqliteodbc
   # For MSSQL: brew tap microsoft/mssql-release && brew install msodbcsql17
   ```

2. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     odbc:
       github: naqvis/crystal-odbc
   ```

3. Run `shards install`

## Usage

### Basic Example

```crystal
require "db"
require "odbc"

DB.open "odbc://DSN=mydb;UID=user;PWD=password" do |db|
  db.exec "create table contacts (name text, age integer)"
  db.exec "insert into contacts values (?, ?)", "John Doe", 30

  puts db.scalar "select max(age) from contacts" # => 30

  db.query "select name, age from contacts" do |rs|
    rs.each do
      puts "#{rs.read(String)} (#{rs.read(Int32)})"
    end
  end
end
```

### Connection Strings

Different databases use different connection string formats:

```crystal
# Using DSN (Data Source Name)
DB.open "odbc://DSN=mydb;UID=user;PWD=password"

# SQLite (file-based)
DB.open "odbc://Driver=SQLITE3;Database=/path/to/database.db"

# SQL Server
DB.open "odbc://Driver=ODBC Driver 17 for SQL Server;Server=localhost;Database=mydb;UID=user;PWD=password"

# Oracle
DB.open "odbc://Driver=Oracle in OraClient19Home1;DBQ=localhost:1521/XE;UID=user;PWD=password"
```

### Configuration

Configure ODBC behavior using environment variables:

```bash
export ODBC_CONNECTION_TIMEOUT=30
export ODBC_QUERY_TIMEOUT=30
export ODBC_ENABLE_TRACING=true
export ODBC_TRACE_FILE=/tmp/odbc.log
```

Refer to [crystal-db](https://github.com/crystal-lang/crystal-db) for more usage instructions.

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
