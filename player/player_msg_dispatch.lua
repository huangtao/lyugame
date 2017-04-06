local pb = require "protobuf"
local skynet = require "skynet"
require "skynet.manager"

require "gameconfig"

local MSG = {}
local config = require "config"
-- local pb = ...

function login( pack )
	-- print("pack", type(pack), pack)
	local account = pack.account or ""
	local password = pack.password or ""

	if account == "" then
		return
	end
	player:login( account, password )
end

function register( pack )
	local account = pack.account
	local password = pack.password

	local ret = skynet.call( ".DBService", "lua", "UserRegister", account, password )
	if ret.result ~= 0 then
		local tbl = {}
		tbl.result = ret.result
		player:sendPacket( "ResRegister", tbl )
		skynet.error("[ERROR] MSG dispatch register failed, account = ", account)
	else
		player:loginSuccess( ret.roleinfo )
	end
end

function enterroom( pack )
	local roomid = pack.roomid
	player:enterRoom( roomid )
end

function leaveroom( pack )
	player:leaveRoom( roomid )
end

function bebanker( pack )
	local t = pack.type
	player:beBanker(t)
end

function unbanker( pack )
	player:unBanker()
end

function keepbanker( pack )
	local iskeep = pack.iskeep
	local gold = pack.gold
	player:keepBanker( iskeep, gold )
end

function bankerbegin( pack )
	player:beginTuibing()
end

function tuibingbet( pack )
	local pos = pack.pos
	local gold = pack.gold
	player:betTuibing(pos, gold)
end

function addgold( pack )
	local gold = pack.gold
	local info = {}
	info.num = gold
	info.log = GoldLog.GM_ADD
	player:addGold( info )
end

function leavequeue()
	player:leaveBankerQueue()
end

function sendmahjong()
	local mj = pack.pai
	player:sendMahJong( mj )
end

MSG = {
	["Reqlogin"] = login,
	["ReqRegister"] = register,
	["ReqEnterRoom"] = enterroom,
	["ReqLeaveRoom"] = leaveroom,
	-- 推饼相关
	["ReqBeBanker"] = bebanker,
	["ReqKeepBanker"] = keepbanker,
	["ReqTuiBingBet"] = tuibingbet,
	["ReqTuiBingBegin"] = bankerbegin,
	["ReqAddGold"] = addgold,
	["ReqTuiBingUnbanker"] = unbanker,
	["ReqTuibingLeaveQueue"] = leavequeue,
	-- 麻将相关
	["ReqMjSendMj"] = sendmahjong,
}

function MSG.MessageDispatch( head, msgbody )
	local func = MSG[head]
	if func then
		local a,b,c = pcall( pb.decode, head, msgbody )
		local code = pb.decode( "tutorial."..head, msgbody )
		if code then
			config.Ldump( code, "["..head.."]" )
			func( code )
		end
	else
		print(string.format("[ERROR] MSG Not define. head[%s]", head))
	end
end

function MSG.Package( head, tbl )
	local code = pb.encode("tutorial." .. head, tbl)
	if code then
		return code
	end
	return nil
end

return MSG