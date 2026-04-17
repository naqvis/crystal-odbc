# crystal-odbc

Crystal ODBC driver implementing the [crystal-db](https://github.com/crystal-lang/crystal-db) API. Provides cross-platform database connectivity through any ODBC Driver Manager for SQLite, SQL Server, Oracle, PostgreSQL, and other ODBC-compatible databases.

## Supported Platforms

| Platform    | ODBC Driver Manager | Install Required?                                        |
| ----------- | ------------------- | -------------------------------------------------------- |
| **Windows** | ODBC32 (built-in)   | No — ships with Windows                                  |
| **macOS**   | unixODBC or iODBC   | Yes — `brew install unixodbc` or build iODBC from source |
| **Linux**   | unixODBC            | Yes — see below                                          |
| **FreeBSD** | unixODBC            | Yes — `pkg install unixODBC`                             |

The library auto-detects the available ODBC Driver Manager at compile time:

- On **Windows**: links against `odbc32.dll` directly (no extra dependencies)
- On **macOS**: uses `pkg-config` to find unixODBC; falls back to iODBC (`libiodbc`) if not found
- On **Linux/Unix**: uses `pkg-config` to find unixODBC; falls back to `-lodbc`

> **Note on macOS and iODBC**: macOS includes iODBC runtime link stubs but _not_ the development headers. To use iODBC, you need to build it from source ([github.com/openlink/iODBC](https://github.com/openlink/iODBC)). For most users, `brew install unixodbc` is the simpler path.

## Installation

### 1. Install an ODBC Driver Manager (if needed)

**Ubuntu/Debian:**

```bash
sudo apt-get install unixodbc unixodbc-dev
```

**RHEL/Fedora/CentOS:**

```bash
sudo dnf install unixODBC unixODBC-devel
```

**macOS:**

```bash
brew install unixodbc
```

To use iODBC instead (no Homebrew dependency), build from source:

```bash
curl -L -o libiodbc.tar.gz https://github.com/openlink/iODBC/releases/download/v3.52.16/libiodbc-3.52.16.tar.gz
tar xzf libiodbc.tar.gz
cd libiodbc-3.52.16
./configure --prefix=/usr/local --disable-gui
make && sudo make install
```

**Windows:**

No installation needed. ODBC32 is built into Windows.

### 2. Install a database ODBC driver

```bash
# SQLite
sudo apt-get install libsqliteodbc          # Debian/Ubuntu
brew install sqliteodbc                       # macOS

# SQL Server
sudo apt-get install msodbcsql17             # Debian/Ubuntu
brew tap microsoft/mssql-release && brew install msodbcsql17  # macOS

# PostgreSQL
sudo apt-get install odbc-postgresql         # Debian/Ubuntu
brew install psqlodbc                         # macOS
```

### 3. Add the shard dependency

```yaml
dependencies:
  odbc:
    github: naqvis/crystal-odbc
```

```bash
shards install
```

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

# PostgreSQL
DB.open "odbc://Driver=PostgreSQL Unicode;Server=localhost;Database=mydb;UID=user;PWD=password"
```

### Configuration

Configure ODBC behavior programmatically:

```crystal
ODBC::Config.configure do |c|
  c.connection_timeout = 60.seconds
  c.query_timeout = 30.seconds
  c.login_timeout = 15.seconds
  c.auto_commit = true
  c.enable_tracing = false
  c.trace_file = "/tmp/odbc.log"
  c.default_buffer_size = 8192
  c.max_string_length = 65536
end
```

Or via environment variables:

```bash
export ODBC_CONNECTION_TIMEOUT=60
export ODBC_QUERY_TIMEOUT=30
export ODBC_LOGIN_TIMEOUT=15
export ODBC_AUTO_COMMIT=true
export ODBC_ENABLE_TRACING=true
export ODBC_TRACE_FILE=/tmp/odbc.log
export ODBC_BUFFER_SIZE=8192
export ODBC_MAX_STRING_LENGTH=65536
```

Configuration values are applied to each new connection automatically.

Refer to [crystal-db](https://github.com/crystal-lang/crystal-db) for the full API.

## Development

To run all tests (requires SQLite ODBC driver):

```bash
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
