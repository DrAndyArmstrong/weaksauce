--- AA15, My cheap and nasty version of my larger DB library!
-- Must try harder, hack slash hack slash :)

local cur = nil

local conMYSQL = nil
local conSQLITE = nil

local penvMYSQL = nil
local penvSQLITE = nil

local luasql = nil
local SQLite = nil
local conCount = 0

AUTOCLOSE=false
local defaultSettingsFile = "settings.lua"

function closecon() end --AA 27/10/14 Function stub (this function will be defined below)

function initDBconnections()
	closecon()

	cur = nil

	conMYSQL = nil
	conSQLITE = nil

	if penvMYSQL then penvMYSQL:close() end
	if penvSQLITE then penvSQLITE:close() end

	penvMYSQL = nil
	penvSQLITE = nil

	luasql = nil
	SQLite = nil
end

--- Get server password etc settings
function loadDBSettings(filename)
	--dbname, dbuser, dbpass, dbhost, dbport coming from file
	initDBconnections()
	dofile (filename)
end

function getDBSettings()
	return {dbname=dbname, dbuser=dbuser, dbpass=dbpass, dbhost=dbhost, dbport=dbport}
end

function setDBSettings(params)
	initDBconnections()
	dbname=params.dbname
	dbuser=params.dbuser
	dbpass=params.dbpass
	dbhost=params.dbhost
	dbport=params.dbport
end

--By default use local settings.lua
if not dbname then loadDBSettings(defaultSettingsFile) end

--- Checks the cursor type and closes it appropriately
function closeCursor(cursorPointer)
	if type(cursorPointer) == 'userdata' then
		cursorPointer:close()
	end
	cursorPointer = nil
	return cursorPointer
end

--- Checks if passed DBname is nil and if it is, returns the default, else returns original
function checkdb(db_name)
	if db_name == nil then
		return dbname
	else
		return db_name
	end
end

--When fired tells the system to use sqllite connections
function setSQLitePath()
	luasql = require "luasql.sqlite3"
	if penvSQLITE then penvSQLITE:close() end
	penvSQLITE=assert(luasql.sqlite3())
end

function setMYSQL()
	closecon()
	luasql = require "luasql.mysql"
	if penvMYSQL then penvMYSQL:close() end
	penvMYSQL=assert(luasql.mysql())
	SQLite=false;
end

function closecon()
	if cur ~= nil then
		cur = closeCursor(cur)
	end
	if conSQLITE~= nil then
		collectgarbage("collect")
		conSQLITE:close()
		conSQLITE=nil
	end
	if conMYSQL~= nil then
		conMYSQL:close()
		--LG.writeLog("MYSQL CONNECTION CLOSED")
		conMYSQL=nil
	end
end

--- function used to create the SQL connection explicitly
function createConnection(SQLitePath)
	if SQLitePath then
		if penvSQLITE == nil then
			setSQLitePath(SQLitePath)
		end
		if conSQLITE == nil then
			conSQLITE = penvSQLITE:connect(SQLitePath .. dbname .. ".sqlite3")
			assert(conSQLITE, "ERROR- SQLite Database " .. SQLitePath .. dbname .. ".sqlite3 not found")
		end
	else
		if penvMYSQL == nil then
			setMYSQL()
		end
		if conMYSQL == nil then
			local err = nil
			--LG.writeLog("MYSQL CREATED")
			--conMYSQL = penvMYSQL:connect(dbname, dbuser, dbpass, dbhost, dbport)
			--assert(conMYSQL, "ERROR- MYSQL Database " .. dbname .. " not found")
			conMYSQL, err = penvMYSQL:connect(dbname, dbuser, dbpass, dbhost, dbport)
			if not conMYSQL then 
				local status, message = isMySQLRunning()
				if status then
					conMYSQL,err = penvMYSQL:connect(dbname, dbuser, dbpass, dbhost, dbport)
					SM.sendEmail("donotreply@cadonix.com", "automated-support@cadonix.com", "Warning: MySQL Rebooted", err, true, "Administrator")
				end
			end
			if not conMYSQL then
				SM.sendEmail("donotreply@cadonix.com", "automated-support@cadonix.com", "Warning: MySQL not able to reboot", err, true, "Administrator")
				error("SQL Database Connection Error - [" .. (err or "") .. "]")
			end
		end
	end
end

-- Execute SQL statement
-- if connection fails assert
-- if cursor is nil (post connection) assert
-- @param SQLstring sql query
-- @param ignoreCursorFail boolean set to true to not assert on nil cursor, default is false
-- @return con DB connection
-- @return cur DB cursor, may be nil
function executeSQL(SQLstring, ignoreCursorFail, SQLitePath)
	if ignoreCursorFail == nil then ignoreCursorFail = false end
	local cur = nil
	local msg = nil
	local err = nil
	--- Define SQL Libraries
	createConnection(SQLitePath)
	if SQLitePath then		
		cur, msg = conSQLITE:execute(SQLstring)
	else		
		--LG.writeLog("MYSQL STATEMENT: " .. SQLstring)
		cur, msg = conMYSQL:execute(SQLstring)
		closecon()
	end

	if not ignoreCursorFail then
	if cur == nil then 
		--if AUTOCLOSE then closecon() end 
		closecon()
	end
	if not msg then msg = '' end
		assert(cur, "ERROR ["..msg.."]- Problem with SQL:".. SQLstring .. " **" .. (SQLitePath or "") .. "**" )
	else
		if cur == nil then 
			return nil, msg 
		end
	end
	return cur
end



--- Gets data from a table based on whereclause.
-- @param tablename name of table to query
-- @param columns csv string of field names, can also be anything allowed in select syntax (e.g COUNT(*) ro MAX(colname))
-- @param whereclause (optional) where clause minus the word 'where', can include 'and' statements
-- @param db_name (optional) database name, if not provided fall back to settings value
-- @param orderby (optional) order results by string
-- @param groupby (optional) group results by string
-- @return boolean false if there is no data, lua table of {rownum={field_name=value, ...}, ...} if there is
-- @return table of colnames in result set
-- @return the SQL statement used to get the data
-- @return total rowcount of result set
function select(tablename, columns, whereclause, db_name, orderby, groupby, useColNames, distinct)
	local ourdata=false
	local database = checkdb(db_name)
	local SQLstring = [[SELECT ]] 
	if distinct then
		SQLstring = SQLstring .. 'DISTINCT '
	end
	SQLstring = SQLstring .. columns .. [[ FROM `]] .. database .. "`.`" .. tablename .. [[`]]
	if whereclause ~= nil then
		SQLstring = SQLstring .. [[ WHERE ]] .. whereclause
	end
	if orderby ~= nil then
		SQLstring = SQLstring .. [[ ORDER BY ]] .. orderby
	end

	if groupby ~= nil then
		SQLstring = SQLstring .. [[ GROUP BY ]] .. groupby
	end

	local cur = executeSQL(SQLstring)
	local rowcount = 0
	local row = cur:fetch ({}, "n")
	local colNames=""
	if row ~= nil then 
		ourdata={}
		colNames = cur:getcolnames();
		while row do
			rowcount = rowcount + 1
			ourdata[rowcount]={}
			-- if we use ipairs here, we miss null columns
			-- this is a bad thing (TM).
			-- using pairs means we may not be preserving the order of the columns in the row
			-- this is also a bad thing (TM)
			-- so, one answer is to check `useColNames` and if true use pairs, else use ipairs
			-- which is less than satifactory, but preserves functionality in calling code.
			if useColNames then
			for i,v in pairs(row) do
				-- use colname as key for value, tis good, no?
				ourdata[rowcount][colNames[i]]=v
			end
			else
			for i,v in ipairs(row) do
				ourdata[rowcount][i]=v
			end
			end
			row = cur:fetch (row, "n")
		end
	end
	if AUTOCLOSE then closecon() end

	if cur then
		--We do not need CUR anymore --Do we need CON? etc...
		cur = closeCursor(cur)
	end

	--closecon()
	return ourdata, SQLstring, colNames, rowcount 
end






