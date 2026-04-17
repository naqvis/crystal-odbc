require "db"
require "./odbc/**"

module ODBC
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  # Shared ODBC environment handle (one per process, as recommended by the ODBC spec).
  # This enables Driver Manager-level connection pooling and reduces resource usage.
  @@env_handle : LibODBC::Sqlhandle?
  @@env_mutex = Mutex.new

  def self.env_handle : LibODBC::Sqlhandle
    @@env_handle || @@env_mutex.synchronize do
      # Double-check after acquiring lock
      @@env_handle || begin
        handle = uninitialized LibODBC::Sqlhandle

        # Allocate the environment handle
        check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_ENV, nil, pointerof(handle)),
          "failed to allocate ODBC environment handle"

        # Set ODBC version — try 3.80 first, fall back to 3.0 (iODBC doesn't support 3.80)
        val_380 = Pointer(Void).new(LibODBC::SQL_OV_ODBC3_80.to_u64)
        ret = LibODBC.sql_set_env_attr(handle, LibODBC::SQL_ATTR_ODBC_VERSION, val_380, 0)
        unless success?(ret)
          val_3 = Pointer(Void).new(LibODBC::SQL_OV_ODBC3.to_u64)
          ret = LibODBC.sql_set_env_attr(handle, LibODBC::SQL_ATTR_ODBC_VERSION, val_3, 0)
          unless success?(ret)
            LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_ENV, handle)
            raise Error.new("failed to set ODBC version on environment handle")
          end
        end

        # Enable connection pooling at the Driver Manager level
        pool_val = Pointer(Void).new(LibODBC::SQL_CP_ONE_PER_HENV.to_u64)
        LibODBC.sql_set_env_attr(handle, LibODBC::SQL_ATTR_CONNECTION_POOLING, pool_val, 0)
        # Pooling is best-effort — not all Driver Managers support it, so we don't check the return

        @@env_handle = handle
        handle
      end
    end
  end
end
