require "db"
require "./odbc/**"

module ODBC
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
