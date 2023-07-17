class ODBC::Driver < DB::Driver
  def build_connection(context : DB::ConnectionContext) : ODBC::Connection
    ODBC::Connection.new(context)
  end

  class ConnectionBuilder < ::DB::ConnectionBuilder
    def initialize(@options : ::DB::Connection::Options, @odbc_options : ODBC::Connection::Options)
    end

    def build : ::DB::Connection
      ODBC::Connection.new(@options, @odbc_options)
    end
  end

  def connection_builder(uri : URI) : ::DB::ConnectionBuilder
    params = HTTP::Params.parse(uri.query || "")
    ConnectionBuilder.new(connection_options(params), ODBC::Connection::Options.from_uri(uri))
  end
end

DB.register_driver "odbc", ODBC::Driver
