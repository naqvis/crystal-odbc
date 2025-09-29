module ODBC
  # Configuration options for ODBC connections and operations
  class Config
    property connection_timeout : Time::Span = 30.seconds
    property query_timeout : Time::Span = 30.seconds
    property login_timeout : Time::Span = 15.seconds
    property? enable_tracing : Bool = false
    property trace_file : String = "/tmp/odbc.log"
    property default_buffer_size : Int32 = 8192
    property max_string_length : Int32 = 65536
    property? auto_commit : Bool = true

    # Global configuration instance
    @@instance : Config?

    def self.instance : Config
      @@instance ||= Config.new
    end

    def self.configure(&) : Nil
      yield instance
    end

    # Load configuration from environment variables
    def self.from_env : Config
      config = Config.new

      if timeout = ENV["ODBC_CONNECTION_TIMEOUT"]?
        config.connection_timeout = timeout.to_i.seconds
      end

      if timeout = ENV["ODBC_QUERY_TIMEOUT"]?
        config.query_timeout = timeout.to_i.seconds
      end

      if timeout = ENV["ODBC_LOGIN_TIMEOUT"]?
        config.login_timeout = timeout.to_i.seconds
      end

      if trace = ENV["ODBC_ENABLE_TRACING"]?
        config.enable_tracing = trace.downcase.in?("true", "1", "yes", "on")
      end

      if file = ENV["ODBC_TRACE_FILE"]?
        config.trace_file = file
      end

      if size = ENV["ODBC_BUFFER_SIZE"]?
        config.default_buffer_size = size.to_i
      end

      if length = ENV["ODBC_MAX_STRING_LENGTH"]?
        config.max_string_length = length.to_i
      end

      if commit = ENV["ODBC_AUTO_COMMIT"]?
        config.auto_commit = commit.downcase.in?("true", "1", "yes", "on")
      end

      config
    end
  end
end
