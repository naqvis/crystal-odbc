@[Link(ldflags: "`command -v pkg-config > /dev/null && pkg-config --libs odbc 2> /dev/null|| printf %s '--lodbc'`")]
lib LibODBC
  alias Sqlhandle = Void*
  alias Sqlhenv = Sqlhandle
  alias Sqlhdbc = Sqlhandle
  alias Sqlsmallint = LibC::Short
  alias Sqlreturn = Sqlsmallint
  alias Sqlhstmt = Sqlhandle
  alias Sqlusmallint = LibC::UShort
  alias Sqlpointer = Void*
  alias Sqllen = LibC::Long
  alias Sqlulen = LibC::ULong
  alias Sqlchar = UInt8
  alias Sqlhdesc = Sqlhandle
  alias Sqlinteger = LibC::Int
  alias Sqlhwnd = Void*
  alias Sqluinteger = LibC::UInt
  alias Sqlsetposirow = LibC::ULong
  alias Wchar = LibC::UShort
  alias Sqlwchar = Wchar

  struct Date
    year : Sqlsmallint
    month : Sqlsmallint
    day : Sqlsmallint
  end

  struct Time
    hour : Sqlsmallint
    minute : Sqlsmallint
    second : Sqlsmallint
  end

  struct TimeStamp
    year : Sqlsmallint
    month : Sqlsmallint
    day : Sqlsmallint
    hour : Sqlsmallint
    minute : Sqlsmallint
    second : Sqlsmallint
    fraction : Sqluinteger
  end

  fun sql_alloc_connect = SQLAllocConnect(environment_handle : Sqlhenv, connection_handle : Sqlhdbc*) : Sqlreturn
  fun sql_alloc_env = SQLAllocEnv(environment_handle : Sqlhenv*) : Sqlreturn
  fun sql_alloc_handle = SQLAllocHandle(handle_type : Sqlsmallint, input_handle : Sqlhandle, output_handle : Sqlhandle*) : Sqlreturn
  fun sql_alloc_stmt = SQLAllocStmt(connection_handle : Sqlhdbc, statement_handle : Sqlhstmt*) : Sqlreturn

  fun sql_bind_col = SQLBindCol(statement_handle : Sqlhstmt, column_number : Sqlusmallint, target_type : Sqlsmallint, target_value : Sqlpointer, buffer_length : Sqllen, str_len_or_ind : Sqllen*) : Sqlreturn

  fun sql_bind_param = SQLBindParam(statement_handle : Sqlhstmt, parameter_number : Sqlusmallint, value_type : Sqlsmallint, parameter_type : Sqlsmallint, length_precision : Sqlulen, parameter_scale : Sqlsmallint, parameter_value : Sqlpointer, str_len_or_ind : Sqllen*) : Sqlreturn

  fun sql_cancel = SQLCancel(statement_handle : Sqlhstmt) : Sqlreturn
  fun sql_cancel_handle = SQLCancelHandle(handle_type : Sqlsmallint, input_handle : Sqlhandle) : Sqlreturn
  fun sql_close_cursor = SQLCloseCursor(statement_handle : Sqlhstmt) : Sqlreturn
  fun sql_col_attribute = SQLColAttribute(statement_handle : Sqlhstmt, column_number : Sqlusmallint, field_identifier : Sqlusmallint, character_attribute : Sqlpointer, buffer_length : Sqlsmallint, string_length : Sqlsmallint*, numeric_attribute : Sqllen*) : Sqlreturn
  fun sql_columns = SQLColumns(statement_handle : Sqlhstmt, catalog_name : Sqlchar*, name_length1 : Sqlsmallint, schema_name : Sqlchar*, name_length2 : Sqlsmallint, table_name : Sqlchar*, name_length3 : Sqlsmallint, column_name : Sqlchar*, name_length4 : Sqlsmallint) : Sqlreturn

  fun sql_connect = SQLConnect(connection_handle : Sqlhdbc, server_name : Sqlchar*, name_length1 : Sqlsmallint, user_name : Sqlchar*, name_length2 : Sqlsmallint, authentication : Sqlchar*, name_length3 : Sqlsmallint) : Sqlreturn
  fun sql_copy_desc = SQLCopyDesc(source_desc_handle : Sqlhdesc, target_desc_handle : Sqlhdesc) : Sqlreturn

  fun sql_data_sources = SQLDataSources(environment_handle : Sqlhenv, direction : Sqlusmallint, server_name : Sqlchar*, buffer_length1 : Sqlsmallint, name_length1 : Sqlsmallint*, description : Sqlchar*, buffer_length2 : Sqlsmallint, name_length2 : Sqlsmallint*) : Sqlreturn
  fun sql_describe_col = SQLDescribeCol(statement_handle : Sqlhstmt, column_number : Sqlusmallint, column_name : Sqlchar*, buffer_length : Sqlsmallint, name_length : Sqlsmallint*, data_type : Sqlsmallint*, column_size : Sqlulen*, decimal_digits : Sqlsmallint*, nullable : Sqlsmallint*) : Sqlreturn
  fun sql_disconnect = SQLDisconnect(connection_handle : Sqlhdbc) : Sqlreturn
  fun sql_end_tran = SQLEndTran(handle_type : Sqlsmallint, handle : Sqlhandle, completion_type : Sqlsmallint) : Sqlreturn
  fun sql_error = SQLError(environment_handle : Sqlhenv, connection_handle : Sqlhdbc, statement_handle : Sqlhstmt, sqlstate : Sqlchar*, native_error : Sqlinteger*, message_text : Sqlchar*, buffer_length : Sqlsmallint, text_length : Sqlsmallint*) : Sqlreturn

  fun sql_exec_direct = SQLExecDirect(statement_handle : Sqlhstmt, statement_text : Sqlchar*, text_length : Sqlinteger) : Sqlreturn
  fun sql_execute = SQLExecute(statement_handle : Sqlhstmt) : Sqlreturn
  fun sql_fetch = SQLFetch(statement_handle : Sqlhstmt) : Sqlreturn
  fun sql_fetch_scroll = SQLFetchScroll(statement_handle : Sqlhstmt, fetch_orientation : Sqlsmallint, fetch_offset : Sqllen) : Sqlreturn
  fun sql_free_connect = SQLFreeConnect(connection_handle : Sqlhdbc) : Sqlreturn
  fun sql_free_env = SQLFreeEnv(environment_handle : Sqlhenv) : Sqlreturn
  fun sql_free_handle = SQLFreeHandle(handle_type : Sqlsmallint, handle : Sqlhandle) : Sqlreturn
  fun sql_free_stmt = SQLFreeStmt(statement_handle : Sqlhstmt, option : Sqlusmallint) : Sqlreturn
  fun sql_get_connect_attr = SQLGetConnectAttr(connection_handle : Sqlhdbc, attribute : Sqlinteger, value : Sqlpointer, buffer_length : Sqlinteger, string_length : Sqlinteger*) : Sqlreturn
  fun sql_get_connect_option = SQLGetConnectOption(connection_handle : Sqlhdbc, option : Sqlusmallint, value : Sqlpointer) : Sqlreturn
  fun sql_get_cursor_name = SQLGetCursorName(statement_handle : Sqlhstmt, cursor_name : Sqlchar*, buffer_length : Sqlsmallint, name_length : Sqlsmallint*) : Sqlreturn
  fun sql_get_data = SQLGetData(statement_handle : Sqlhstmt, column_number : Sqlusmallint, target_type : Sqlsmallint, target_value : Sqlpointer, buffer_length : Sqllen, str_len_or_ind : Sqllen*) : Sqlreturn
  fun sql_get_desc_field = SQLGetDescField(descriptor_handle : Sqlhdesc, rec_number : Sqlsmallint, field_identifier : Sqlsmallint, value : Sqlpointer, buffer_length : Sqlinteger, string_length : Sqlinteger*) : Sqlreturn
  fun sql_get_desc_rec = SQLGetDescRec(descriptor_handle : Sqlhdesc, rec_number : Sqlsmallint, name : Sqlchar*, buffer_length : Sqlsmallint, string_length : Sqlsmallint*, type : Sqlsmallint*, sub_type : Sqlsmallint*, length : Sqllen*, precision : Sqlsmallint*, scale : Sqlsmallint*, nullable : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_field = SQLGetDiagField(handle_type : Sqlsmallint, handle : Sqlhandle, rec_number : Sqlsmallint, diag_identifier : Sqlsmallint, diag_info : Sqlpointer, buffer_length : Sqlsmallint, string_length : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_rec = SQLGetDiagRec(handle_type : Sqlsmallint, handle : Sqlhandle, rec_number : Sqlsmallint, sqlstate : Sqlchar*, native_error : Sqlinteger*, message_text : Sqlchar*, buffer_length : Sqlsmallint, text_length : Sqlsmallint*) : Sqlreturn
  fun sql_get_env_attr = SQLGetEnvAttr(environment_handle : Sqlhenv, attribute : Sqlinteger, value : Sqlpointer, buffer_length : Sqlinteger, string_length : Sqlinteger*) : Sqlreturn
  fun sql_get_functions = SQLGetFunctions(connection_handle : Sqlhdbc, function_id : Sqlusmallint, supported : Sqlusmallint*) : Sqlreturn
  fun sql_get_info = SQLGetInfo(connection_handle : Sqlhdbc, info_type : Sqlusmallint, info_value : Sqlpointer, buffer_length : Sqlsmallint, string_length : Sqlsmallint*) : Sqlreturn
  fun sql_get_stmt_attr = SQLGetStmtAttr(statement_handle : Sqlhstmt, attribute : Sqlinteger, value : Sqlpointer, buffer_length : Sqlinteger, string_length : Sqlinteger*) : Sqlreturn
  fun sql_get_stmt_option = SQLGetStmtOption(statement_handle : Sqlhstmt, option : Sqlusmallint, value : Sqlpointer) : Sqlreturn
  fun sql_get_type_info = SQLGetTypeInfo(statement_handle : Sqlhstmt, data_type : Sqlsmallint) : Sqlreturn
  fun sql_num_result_cols = SQLNumResultCols(statement_handle : Sqlhstmt, column_count : Sqlsmallint*) : Sqlreturn
  fun sql_param_data = SQLParamData(statement_handle : Sqlhstmt, value : Sqlpointer*) : Sqlreturn
  fun sql_prepare = SQLPrepare(statement_handle : Sqlhstmt, statement_text : Sqlchar*, text_length : Sqlinteger) : Sqlreturn
  fun sql_put_data = SQLPutData(statement_handle : Sqlhstmt, data : Sqlpointer, str_len_or_ind : Sqllen) : Sqlreturn
  fun sql_row_count = SQLRowCount(statement_handle : Sqlhstmt, row_count : Sqllen*) : Sqlreturn
  fun sql_set_connect_attr = SQLSetConnectAttr(connection_handle : Sqlhdbc, attribute : Sqlinteger, value : Sqlpointer, string_length : Sqlinteger) : Sqlreturn
  fun sql_set_connect_option = SQLSetConnectOption(connection_handle : Sqlhdbc, option : Sqlusmallint, value : Sqlulen) : Sqlreturn
  fun sql_set_cursor_name = SQLSetCursorName(statement_handle : Sqlhstmt, cursor_name : Sqlchar*, name_length : Sqlsmallint) : Sqlreturn
  fun sql_set_desc_field = SQLSetDescField(descriptor_handle : Sqlhdesc, rec_number : Sqlsmallint, field_identifier : Sqlsmallint, value : Sqlpointer, buffer_length : Sqlinteger) : Sqlreturn
  fun sql_set_desc_rec = SQLSetDescRec(descriptor_handle : Sqlhdesc, rec_number : Sqlsmallint, type : Sqlsmallint, sub_type : Sqlsmallint, length : Sqllen, precision : Sqlsmallint, scale : Sqlsmallint, data : Sqlpointer, string_length : Sqllen*, indicator : Sqllen*) : Sqlreturn
  fun sql_set_env_attr = SQLSetEnvAttr(environment_handle : Sqlhenv, attribute : Sqlinteger, value : Sqlpointer, string_length : Sqlinteger) : Sqlreturn
  fun sql_set_param = SQLSetParam(statement_handle : Sqlhstmt, parameter_number : Sqlusmallint, value_type : Sqlsmallint, parameter_type : Sqlsmallint, length_precision : Sqlulen, parameter_scale : Sqlsmallint, parameter_value : Sqlpointer, str_len_or_ind : Sqllen*) : Sqlreturn
  fun sql_set_stmt_attr = SQLSetStmtAttr(statement_handle : Sqlhstmt, attribute : Sqlinteger, value : Sqlpointer, string_length : Sqlinteger) : Sqlreturn
  fun sql_set_stmt_option = SQLSetStmtOption(statement_handle : Sqlhstmt, option : Sqlusmallint, value : Sqlulen) : Sqlreturn
  fun sql_special_columns = SQLSpecialColumns(statement_handle : Sqlhstmt, identifier_type : Sqlusmallint, catalog_name : Sqlchar*, name_length1 : Sqlsmallint, schema_name : Sqlchar*, name_length2 : Sqlsmallint, table_name : Sqlchar*, name_length3 : Sqlsmallint, scope : Sqlusmallint, nullable : Sqlusmallint) : Sqlreturn
  fun sql_statistics = SQLStatistics(statement_handle : Sqlhstmt, catalog_name : Sqlchar*, name_length1 : Sqlsmallint, schema_name : Sqlchar*, name_length2 : Sqlsmallint, table_name : Sqlchar*, name_length3 : Sqlsmallint, unique : Sqlusmallint, reserved : Sqlusmallint) : Sqlreturn
  fun sql_tables = SQLTables(statement_handle : Sqlhstmt, catalog_name : Sqlchar*, name_length1 : Sqlsmallint, schema_name : Sqlchar*, name_length2 : Sqlsmallint, table_name : Sqlchar*, name_length3 : Sqlsmallint, table_type : Sqlchar*, name_length4 : Sqlsmallint) : Sqlreturn
  fun sql_transact = SQLTransact(environment_handle : Sqlhenv, connection_handle : Sqlhdbc, completion_type : Sqlusmallint) : Sqlreturn
  fun sql_driver_connect = SQLDriverConnect(hdbc : Sqlhdbc, hwnd : Sqlhwnd, sz_conn_str_in : Sqlchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*, f_driver_completion : Sqlusmallint) : Sqlreturn

  fun sql_browse_connect = SQLBrowseConnect(hdbc : Sqlhdbc, sz_conn_str_in : Sqlchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*) : Sqlreturn
  fun sql_bulk_operations = SQLBulkOperations(statement_handle : Sqlhstmt, operation : Sqlsmallint) : Sqlreturn
  fun sql_col_attributes = SQLColAttributes(hstmt : Sqlhstmt, icol : Sqlusmallint, f_desc_type : Sqlusmallint, rgb_desc : Sqlpointer, cb_desc_max : Sqlsmallint, pcb_desc : Sqlsmallint*, pf_desc : Sqllen*) : Sqlreturn
  fun sql_column_privileges = SQLColumnPrivileges(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, sz_column_name : Sqlchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_describe_param = SQLDescribeParam(hstmt : Sqlhstmt, ipar : Sqlusmallint, pf_sql_type : Sqlsmallint*, pcb_param_def : Sqlulen*, pib_scale : Sqlsmallint*, pf_nullable : Sqlsmallint*) : Sqlreturn
  fun sql_extended_fetch = SQLExtendedFetch(hstmt : Sqlhstmt, f_fetch_type : Sqlusmallint, irow : Sqllen, pcrow : Sqlulen*, rgf_row_status : Sqlusmallint*) : Sqlreturn
  fun sql_foreign_keys = SQLForeignKeys(hstmt : Sqlhstmt, sz_pk_catalog_name : Sqlchar*, cb_pk_catalog_name : Sqlsmallint, sz_pk_schema_name : Sqlchar*, cb_pk_schema_name : Sqlsmallint, sz_pk_table_name : Sqlchar*, cb_pk_table_name : Sqlsmallint, sz_fk_catalog_name : Sqlchar*, cb_fk_catalog_name : Sqlsmallint, sz_fk_schema_name : Sqlchar*, cb_fk_schema_name : Sqlsmallint, sz_fk_table_name : Sqlchar*, cb_fk_table_name : Sqlsmallint) : Sqlreturn
  fun sql_more_results = SQLMoreResults(hstmt : Sqlhstmt) : Sqlreturn
  fun sql_native_sql = SQLNativeSql(hdbc : Sqlhdbc, sz_sql_str_in : Sqlchar*, cb_sql_str_in : Sqlinteger, sz_sql_str : Sqlchar*, cb_sql_str_max : Sqlinteger, pcb_sql_str : Sqlinteger*) : Sqlreturn
  fun sql_num_params = SQLNumParams(hstmt : Sqlhstmt, pcpar : Sqlsmallint*) : Sqlreturn
  fun sql_param_options = SQLParamOptions(hstmt : Sqlhstmt, crow : Sqlulen, pirow : Sqlulen*) : Sqlreturn
  fun sql_primary_keys = SQLPrimaryKeys(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_procedure_columns = SQLProcedureColumns(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlchar*, cb_proc_name : Sqlsmallint, sz_column_name : Sqlchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_procedures = SQLProcedures(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlchar*, cb_proc_name : Sqlsmallint) : Sqlreturn
  fun sql_set_pos = SQLSetPos(hstmt : Sqlhstmt, irow : Sqlsetposirow, f_option : Sqlusmallint, f_lock : Sqlusmallint) : Sqlreturn

  fun sql_table_privileges = SQLTablePrivileges(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_drivers = SQLDrivers(henv : Sqlhenv, f_direction : Sqlusmallint, sz_driver_desc : Sqlchar*, cb_driver_desc_max : Sqlsmallint, pcb_driver_desc : Sqlsmallint*, sz_driver_attributes : Sqlchar*, cb_drvr_attr_max : Sqlsmallint, pcb_drvr_attr : Sqlsmallint*) : Sqlreturn
  fun sql_bind_parameter = SQLBindParameter(hstmt : Sqlhstmt, ipar : Sqlusmallint, f_param_type : Sqlsmallint, f_c_type : Sqlsmallint, f_sql_type : Sqlsmallint, cb_col_def : Sqlulen, ib_scale : Sqlsmallint, rgb_value : Sqlpointer, cb_value_max : Sqllen, pcb_value : Sqllen*) : Sqlreturn
  fun sql_alloc_handle_std = SQLAllocHandleStd(f_handle_type : Sqlsmallint, h_input : Sqlhandle, ph_output : Sqlhandle*) : Sqlreturn
  fun sql_set_scroll_options = SQLSetScrollOptions(hstmt : Sqlhstmt, f_concurrency : Sqlusmallint, crow_keyset : Sqllen, crow_rowset : Sqlusmallint) : Sqlreturn
  fun sql_col_attribute_w = SQLColAttributeW(hstmt : Sqlhstmt, i_col : Sqlusmallint, i_field : Sqlusmallint, p_char_attr : Sqlpointer, cb_char_attr_max : Sqlsmallint, pcb_char_attr : Sqlsmallint*, p_num_attr : Sqllen*) : Sqlreturn
  fun sql_col_attributes_w = SQLColAttributesW(hstmt : Sqlhstmt, icol : Sqlusmallint, f_desc_type : Sqlusmallint, rgb_desc : Sqlpointer, cb_desc_max : Sqlsmallint, pcb_desc : Sqlsmallint*, pf_desc : Sqllen*) : Sqlreturn
  fun sql_connect_w = SQLConnectW(hdbc : Sqlhdbc, sz_dsn : Sqlwchar*, cb_dsn : Sqlsmallint, sz_uid : Sqlwchar*, cb_uid : Sqlsmallint, sz_auth_str : Sqlwchar*, cb_auth_str : Sqlsmallint) : Sqlreturn

  fun sql_describe_col_w = SQLDescribeColW(hstmt : Sqlhstmt, icol : Sqlusmallint, sz_col_name : Sqlwchar*, cb_col_name_max : Sqlsmallint, pcb_col_name : Sqlsmallint*, pf_sql_type : Sqlsmallint*, pcb_col_def : Sqlulen*, pib_scale : Sqlsmallint*, pf_nullable : Sqlsmallint*) : Sqlreturn
  fun sql_error_w = SQLErrorW(henv : Sqlhenv, hdbc : Sqlhdbc, hstmt : Sqlhstmt, sz_sql_state : Sqlwchar*, pf_native_error : Sqlinteger*, sz_error_msg : Sqlwchar*, cb_error_msg_max : Sqlsmallint, pcb_error_msg : Sqlsmallint*) : Sqlreturn
  fun sql_exec_direct_w = SQLExecDirectW(hstmt : Sqlhstmt, sz_sql_str : Sqlwchar*, cb_sql_str : Sqlinteger) : Sqlreturn
  fun sql_get_connect_attr_w = SQLGetConnectAttrW(hdbc : Sqlhdbc, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_get_cursor_name_w = SQLGetCursorNameW(hstmt : Sqlhstmt, sz_cursor : Sqlwchar*, cb_cursor_max : Sqlsmallint, pcb_cursor : Sqlsmallint*) : Sqlreturn
  fun sql_set_desc_field_w = SQLSetDescFieldW(descriptor_handle : Sqlhdesc, rec_number : Sqlsmallint, field_identifier : Sqlsmallint, value : Sqlpointer, buffer_length : Sqlinteger) : Sqlreturn
  fun sql_get_desc_field_w = SQLGetDescFieldW(hdesc : Sqlhdesc, i_record : Sqlsmallint, i_field : Sqlsmallint, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_get_desc_rec_w = SQLGetDescRecW(hdesc : Sqlhdesc, i_record : Sqlsmallint, sz_name : Sqlwchar*, cb_name_max : Sqlsmallint, pcb_name : Sqlsmallint*, pf_type : Sqlsmallint*, pf_sub_type : Sqlsmallint*, p_length : Sqllen*, p_precision : Sqlsmallint*, p_scale : Sqlsmallint*, p_nullable : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_field_w = SQLGetDiagFieldW(f_handle_type : Sqlsmallint, handle : Sqlhandle, i_record : Sqlsmallint, f_diag_field : Sqlsmallint, rgb_diag_info : Sqlpointer, cb_diag_info_max : Sqlsmallint, pcb_diag_info : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_rec_w = SQLGetDiagRecW(f_handle_type : Sqlsmallint, handle : Sqlhandle, i_record : Sqlsmallint, sz_sql_state : Sqlwchar*, pf_native_error : Sqlinteger*, sz_error_msg : Sqlwchar*, cb_error_msg_max : Sqlsmallint, pcb_error_msg : Sqlsmallint*) : Sqlreturn
  fun sql_prepare_w = SQLPrepareW(hstmt : Sqlhstmt, sz_sql_str : Sqlwchar*, cb_sql_str : Sqlinteger) : Sqlreturn
  fun sql_set_connect_attr_w = SQLSetConnectAttrW(hdbc : Sqlhdbc, f_attribute : Sqlinteger, rgb_value : Sqlinteger, cb_value : Sqlinteger) : Sqlreturn
  fun sql_set_cursor_name_w = SQLSetCursorNameW(hstmt : Sqlhstmt, sz_cursor : Sqlwchar*, cb_cursor : Sqlsmallint) : Sqlreturn
  fun sql_columns_w = SQLColumnsW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint, sz_column_name : Sqlwchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_get_connect_option_w = SQLGetConnectOptionW(hdbc : Sqlhdbc, f_option : Sqlusmallint, pv_param : Sqlpointer) : Sqlreturn
  fun sql_get_info_w = SQLGetInfoW(hdbc : Sqlhdbc, f_info_type : Sqlusmallint, rgb_info_value : Sqlpointer, cb_info_value_max : Sqlsmallint, pcb_info_value : Sqlsmallint*) : Sqlreturn
  fun sql_get_type_info_w = SQLGetTypeInfoW(statement_handle : Sqlhstmt, data_type : Sqlsmallint) : Sqlreturn
  fun sql_set_connect_option_w = SQLSetConnectOptionW(hdbc : Sqlhdbc, f_option : Sqlusmallint, v_param : Sqlulen) : Sqlreturn
  fun sql_special_columns_w = SQLSpecialColumnsW(hstmt : Sqlhstmt, f_col_type : Sqlusmallint, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint, f_scope : Sqlusmallint, f_nullable : Sqlusmallint) : Sqlreturn
  fun sql_statistics_w = SQLStatisticsW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint, f_unique : Sqlusmallint, f_accuracy : Sqlusmallint) : Sqlreturn
  fun sql_tables_w = SQLTablesW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint, sz_table_type : Sqlwchar*, cb_table_type : Sqlsmallint) : Sqlreturn
  fun sql_data_sources_w = SQLDataSourcesW(henv : Sqlhenv, f_direction : Sqlusmallint, sz_dsn : Sqlwchar*, cb_dsn_max : Sqlsmallint, pcb_dsn : Sqlsmallint*, sz_description : Sqlwchar*, cb_description_max : Sqlsmallint, pcb_description : Sqlsmallint*) : Sqlreturn
  fun sql_driver_connect_w = SQLDriverConnectW(hdbc : Sqlhdbc, hwnd : Sqlhwnd, sz_conn_str_in : Sqlwchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlwchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*, f_driver_completion : Sqlusmallint) : Sqlreturn
  fun sql_browse_connect_w = SQLBrowseConnectW(hdbc : Sqlhdbc, sz_conn_str_in : Sqlwchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlwchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*) : Sqlreturn
  fun sql_column_privileges_w = SQLColumnPrivilegesW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint, sz_column_name : Sqlwchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_get_stmt_attr_w = SQLGetStmtAttrW(hstmt : Sqlhstmt, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_set_stmt_attr_w = SQLSetStmtAttrW(hstmt : Sqlhstmt, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value_max : Sqlinteger) : Sqlreturn
  fun sql_foreign_keys_w = SQLForeignKeysW(hstmt : Sqlhstmt, sz_pk_catalog_name : Sqlwchar*, cb_pk_catalog_name : Sqlsmallint, sz_pk_schema_name : Sqlwchar*, cb_pk_schema_name : Sqlsmallint, sz_pk_table_name : Sqlwchar*, cb_pk_table_name : Sqlsmallint, sz_fk_catalog_name : Sqlwchar*, cb_fk_catalog_name : Sqlsmallint, sz_fk_schema_name : Sqlwchar*, cb_fk_schema_name : Sqlsmallint, sz_fk_table_name : Sqlwchar*, cb_fk_table_name : Sqlsmallint) : Sqlreturn
  fun sql_native_sql_w = SQLNativeSqlW(hdbc : Sqlhdbc, sz_sql_str_in : Sqlwchar*, cb_sql_str_in : Sqlinteger, sz_sql_str : Sqlwchar*, cb_sql_str_max : Sqlinteger, pcb_sql_str : Sqlinteger*) : Sqlreturn
  fun sql_primary_keys_w = SQLPrimaryKeysW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_procedure_columns_w = SQLProcedureColumnsW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlwchar*, cb_proc_name : Sqlsmallint, sz_column_name : Sqlwchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_procedures_w = SQLProceduresW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlwchar*, cb_proc_name : Sqlsmallint) : Sqlreturn
  fun sql_table_privileges_w = SQLTablePrivilegesW(hstmt : Sqlhstmt, sz_catalog_name : Sqlwchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlwchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlwchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_drivers_w = SQLDriversW(henv : Sqlhenv, f_direction : Sqlusmallint, sz_driver_desc : Sqlwchar*, cb_driver_desc_max : Sqlsmallint, pcb_driver_desc : Sqlsmallint*, sz_driver_attributes : Sqlwchar*, cb_drvr_attr_max : Sqlsmallint, pcb_drvr_attr : Sqlsmallint*) : Sqlreturn
  fun sql_col_attribute_a = SQLColAttributeA(hstmt : Sqlhstmt, i_col : Sqlsmallint, i_field : Sqlsmallint, p_char_attr : Sqlpointer, cb_char_attr_max : Sqlsmallint, pcb_char_attr : Sqlsmallint*, p_num_attr : Sqllen*) : Sqlreturn
  fun sql_col_attributes_a = SQLColAttributesA(hstmt : Sqlhstmt, icol : Sqlusmallint, f_desc_type : Sqlusmallint, rgb_desc : Sqlpointer, cb_desc_max : Sqlsmallint, pcb_desc : Sqlsmallint*, pf_desc : Sqllen*) : Sqlreturn
  fun sql_connect_a = SQLConnectA(hdbc : Sqlhdbc, sz_dsn : Sqlchar*, cb_dsn : Sqlsmallint, sz_uid : Sqlchar*, cb_uid : Sqlsmallint, sz_auth_str : Sqlchar*, cb_auth_str : Sqlsmallint) : Sqlreturn
  fun sql_describe_col_a = SQLDescribeColA(hstmt : Sqlhstmt, icol : Sqlusmallint, sz_col_name : Sqlchar*, cb_col_name_max : Sqlsmallint, pcb_col_name : Sqlsmallint*, pf_sql_type : Sqlsmallint*, pcb_col_def : Sqlulen*, pib_scale : Sqlsmallint*, pf_nullable : Sqlsmallint*) : Sqlreturn
  fun sql_error_a = SQLErrorA(henv : Sqlhenv, hdbc : Sqlhdbc, hstmt : Sqlhstmt, sz_sql_state : Sqlchar*, pf_native_error : Sqlinteger*, sz_error_msg : Sqlchar*, cb_error_msg_max : Sqlsmallint, pcb_error_msg : Sqlsmallint*) : Sqlreturn
  fun sql_exec_direct_a = SQLExecDirectA(hstmt : Sqlhstmt, sz_sql_str : Sqlchar*, cb_sql_str : Sqlinteger) : Sqlreturn
  fun sql_get_connect_attr_a = SQLGetConnectAttrA(hdbc : Sqlhdbc, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_get_cursor_name_a = SQLGetCursorNameA(hstmt : Sqlhstmt, sz_cursor : Sqlchar*, cb_cursor_max : Sqlsmallint, pcb_cursor : Sqlsmallint*) : Sqlreturn
  fun sql_get_desc_field_a = SQLGetDescFieldA(hdesc : Sqlhdesc, i_record : Sqlsmallint, i_field : Sqlsmallint, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_get_desc_rec_a = SQLGetDescRecA(hdesc : Sqlhdesc, i_record : Sqlsmallint, sz_name : Sqlchar*, cb_name_max : Sqlsmallint, pcb_name : Sqlsmallint*, pf_type : Sqlsmallint*, pf_sub_type : Sqlsmallint*, p_length : Sqllen*, p_precision : Sqlsmallint*, p_scale : Sqlsmallint*, p_nullable : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_field_a = SQLGetDiagFieldA(f_handle_type : Sqlsmallint, handle : Sqlhandle, i_record : Sqlsmallint, f_diag_field : Sqlsmallint, rgb_diag_info : Sqlpointer, cb_diag_info_max : Sqlsmallint, pcb_diag_info : Sqlsmallint*) : Sqlreturn
  fun sql_get_diag_rec_a = SQLGetDiagRecA(f_handle_type : Sqlsmallint, handle : Sqlhandle, i_record : Sqlsmallint, sz_sql_state : Sqlchar*, pf_native_error : Sqlinteger*, sz_error_msg : Sqlchar*, cb_error_msg_max : Sqlsmallint, pcb_error_msg : Sqlsmallint*) : Sqlreturn
  fun sql_get_stmt_attr_a = SQLGetStmtAttrA(hstmt : Sqlhstmt, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value_max : Sqlinteger, pcb_value : Sqlinteger*) : Sqlreturn
  fun sql_get_type_info_a = SQLGetTypeInfoA(statement_handle : Sqlhstmt, data_tyoe : Sqlsmallint) : Sqlreturn
  fun sql_prepare_a = SQLPrepareA(hstmt : Sqlhstmt, sz_sql_str : Sqlchar*, cb_sql_str : Sqlinteger) : Sqlreturn
  fun sql_set_connect_attr_a = SQLSetConnectAttrA(hdbc : Sqlhdbc, f_attribute : Sqlinteger, rgb_value : Sqlpointer, cb_value : Sqlinteger) : Sqlreturn
  fun sql_set_cursor_name_a = SQLSetCursorNameA(hstmt : Sqlhstmt, sz_cursor : Sqlchar*, cb_cursor : Sqlsmallint) : Sqlreturn
  fun sql_columns_a = SQLColumnsA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, sz_column_name : Sqlchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_get_connect_option_a = SQLGetConnectOptionA(hdbc : Sqlhdbc, f_option : Sqlusmallint, pv_param : Sqlpointer) : Sqlreturn
  fun sql_get_info_a = SQLGetInfoA(hdbc : Sqlhdbc, f_info_type : Sqlusmallint, rgb_info_value : Sqlpointer, cb_info_value_max : Sqlsmallint, pcb_info_value : Sqlsmallint*) : Sqlreturn
  fun sql_get_stmt_option_a = SQLGetStmtOptionA(hstmt : Sqlhstmt, f_option : Sqlusmallint, pv_param : Sqlpointer) : Sqlreturn
  fun sql_set_connect_option_a = SQLSetConnectOptionA(hdbc : Sqlhdbc, f_option : Sqlusmallint, v_param : Sqlulen) : Sqlreturn
  fun sql_set_stmt_option_a = SQLSetStmtOptionA(hstmt : Sqlhstmt, f_option : Sqlusmallint, v_param : Sqlulen) : Sqlreturn
  fun sql_special_columns_a = SQLSpecialColumnsA(hstmt : Sqlhstmt, f_col_type : Sqlusmallint, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, f_scope : Sqlusmallint, f_nullable : Sqlusmallint) : Sqlreturn
  fun sql_statistics_a = SQLStatisticsA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, f_unique : Sqlusmallint, f_accuracy : Sqlusmallint) : Sqlreturn
  fun sql_tables_a = SQLTablesA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, sz_table_type : Sqlchar*, cb_table_type : Sqlsmallint) : Sqlreturn
  fun sql_data_sources_a = SQLDataSourcesA(henv : Sqlhenv, f_direction : Sqlusmallint, sz_dsn : Sqlchar*, cb_dsn_max : Sqlsmallint, pcb_dsn : Sqlsmallint*, sz_description : Sqlchar*, cb_description_max : Sqlsmallint, pcb_description : Sqlsmallint*) : Sqlreturn
  fun sql_driver_connect_a = SQLDriverConnectA(hdbc : Sqlhdbc, hwnd : Sqlhwnd, sz_conn_str_in : Sqlchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*, f_driver_completion : Sqlusmallint) : Sqlreturn
  fun sql_browse_connect_a = SQLBrowseConnectA(hdbc : Sqlhdbc, sz_conn_str_in : Sqlchar*, cb_conn_str_in : Sqlsmallint, sz_conn_str_out : Sqlchar*, cb_conn_str_out_max : Sqlsmallint, pcb_conn_str_out : Sqlsmallint*) : Sqlreturn
  fun sql_column_privileges_a = SQLColumnPrivilegesA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint, sz_column_name : Sqlchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_describe_param_a = SQLDescribeParamA(hstmt : Sqlhstmt, ipar : Sqlusmallint, pf_sql_type : Sqlsmallint*, pcb_param_def : Sqluinteger*, pib_scale : Sqlsmallint*, pf_nullable : Sqlsmallint*) : Sqlreturn

  fun sql_foreign_keys_a = SQLForeignKeysA(hstmt : Sqlhstmt, sz_pk_catalog_name : Sqlchar*, cb_pk_catalog_name : Sqlsmallint, sz_pk_schema_name : Sqlchar*, cb_pk_schema_name : Sqlsmallint, sz_pk_table_name : Sqlchar*, cb_pk_table_name : Sqlsmallint, sz_fk_catalog_name : Sqlchar*, cb_fk_catalog_name : Sqlsmallint, sz_fk_schema_name : Sqlchar*, cb_fk_schema_name : Sqlsmallint, sz_fk_table_name : Sqlchar*, cb_fk_table_name : Sqlsmallint) : Sqlreturn
  fun sql_native_sql_a = SQLNativeSqlA(hdbc : Sqlhdbc, sz_sql_str_in : Sqlchar*, cb_sql_str_in : Sqlinteger, sz_sql_str : Sqlchar*, cb_sql_str_max : Sqlinteger, pcb_sql_str : Sqlinteger*) : Sqlreturn
  fun sql_primary_keys_a = SQLPrimaryKeysA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_procedure_columns_a = SQLProcedureColumnsA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlchar*, cb_proc_name : Sqlsmallint, sz_column_name : Sqlchar*, cb_column_name : Sqlsmallint) : Sqlreturn
  fun sql_procedures_a = SQLProceduresA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_proc_name : Sqlchar*, cb_proc_name : Sqlsmallint) : Sqlreturn
  fun sql_table_privileges_a = SQLTablePrivilegesA(hstmt : Sqlhstmt, sz_catalog_name : Sqlchar*, cb_catalog_name : Sqlsmallint, sz_schema_name : Sqlchar*, cb_schema_name : Sqlsmallint, sz_table_name : Sqlchar*, cb_table_name : Sqlsmallint) : Sqlreturn
  fun sql_drivers_a = SQLDriversA(henv : Sqlhenv, f_direction : Sqlusmallint, sz_driver_desc : Sqlchar*, cb_driver_desc_max : Sqlsmallint, pcb_driver_desc : Sqlsmallint*, sz_driver_attributes : Sqlchar*, cb_drvr_attr_max : Sqlsmallint, pcb_drvr_attr : Sqlsmallint*) : Sqlreturn
end
