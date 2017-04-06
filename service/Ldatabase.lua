-- Ldatabase.lua

local skynet = require "skynet"
require "skynet.manager"

local mysql = require "mysql"

local CMD = {}

local config = require "config"
require "errorcode"

local db = nil

local sqls = {
	["login"] = "SELECT * FROM user WHERE account='%s';",
	["register"] = "INSERT INTO user (account, name, password, gold) VALUES ('%s', '%s', '%s', 0);\
					SELECT * FROM user WHERE account='%s';",
	["save"] = "UPDATE user SET gold = %d WHERE id = %d",
	["addgold"] = "UPDATE user SET gold = gold + %d WHERE id = %d",
}

function CMD.run( sql )
	local res =  db:query( sql )
	return res
end

function CMD.UserLogin( account, password )
	local sql = string.format( sqls[ "login" ], account ) 
	local res = CMD.run( sql )

	local ret = {}
	ret.result = 0
	if type( res ) == "table" then
		if #res == 0 then
			ret.result = ErrorCode.NO_ACCOUNT
		else
			ret.roleinfo = res[1]
		end
	else
		ret.result = ErrorCode.DBSERVICE_ERROR
		skynet.error("[ERROR] DBService UserLogin failed, account =", account)
	end
	return ret
end

function CMD.UserRegister( account, password )
	local sql = string.format( sqls[ "login" ], account ) 
	local res = CMD.run( sql )

	local ret = {}
	ret.result = 0

	-- config.Ldump( res , "UserRegister" )

	if type( res ) == "table" then
		if #res == 0 then
			sql = string.format( sqls[ "register" ], account, account, password, account )
			config.Lprint(1, "sql", sql )
			res = CMD.run( sql )

			config.Ldump( res , "UserRegister 2" )

			if res.mulitresultset == true then
				ret.roleinfo = res[2][1]
				return ret
			end
		else
			ret.result = ErrorCode.ACCOUNT_REPEAT
		end
	else
		ret.result = ErrorCode.DBSERVICE_ERROR
		skynet.error("[ERROR] DBService UserRegister failed, account =", account)
	end
	
	return ret
end

function CMD.PlayerAddGold( player_id, gold )
	if gold == 0 then
		return 
	end
	local sql = string.format( sqls["addgold"], gold, player_id )
	local res = CMD.run( sql )

	local ret = {}
	config.Ldump( res , "PlayerAddGold" )
end

--[[save player info
	param info need
		player_id
		player_gold
]]
function CMD.savePlayer( info )
	local sql = string.format( sqls[ "save" ], info.player_gold, info.player_id ) 
	config.Lprint( 1, "sql = ", sql )
	local res = CMD.run( sql )
	config.Ldump( res , "DB savePlayer" )
end

skynet.start(function()
	local function on_connect(db)
		db:query("set charset utf8");
	end
	
	db = mysql.connect({
		host 		= 	config.database_config.ip,		 
		port 		= 	config.database_config.port,
		database 	= 	config.database_config.database,
		user 		= 	config.database_config.user,
		password	= 	config.database_config.password,
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})
	if not db then
		skynet.error("failed to connect")
	end
	skynet.error("success to connect to mysql server")

	skynet.dispatch( "lua", function(_,_, command, ...)
    	-- 注意命令方法 不要跟消息方法 重名，否则将会出错
		local f = CMD[command]
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
	end)
	-- skynet.name(".DBService", skynet.self())
	skynet.register(".DBService")
end)


