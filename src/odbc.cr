require "db"
require "./odbc/**"

module ODBC
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  # Configuration is initialized lazily via Config.instance
end
