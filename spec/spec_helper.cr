require "spec"
require "../src/odbc"

include ODBC

DB_FILENAME = "./test.db"
DSN         = "odbc://Driver=SQLITE3;Database="

def with_db(&block : DB::Database ->)
  File.delete(DB_FILENAME) rescue nil
  DB.open "#{DSN}#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_cnn(&block : DB::Connection ->)
  File.delete(DB_FILENAME) rescue nil
  DB.connect "#{DSN}#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_db(config, &block : DB::Database ->)
  uri = "#{DSN}#{DB_FILENAME}#{config}"
  File.delete(DB_FILENAME) rescue nil
  DB.open uri, &block
ensure
  File.delete(DB_FILENAME)
end
