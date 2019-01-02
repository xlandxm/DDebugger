DDebuger = DDebuger or {}

local bpFile = [[E:\\DDebugger\\breakpoint.txt]]

------------------------HandlerList beg----------------------
-- quit/q
local quitHandler = function () 
	DDebuger.isBreak = false 
end

-- print/p
local printHandler = function (paramList) 
	if #paramList <= 0 then
		return
	end
	local key = paramList[1]
	local resultList = DDebuger.GetLocalAndUpValueLua(key)

	for i, v in ipairs(resultList) do
		DDebuger:Print(v)
	end
end

-- next/n
local nextHandler = function ()
	DDebuger.isBreak = false
	DDebuger.isSingleStep = true
end

local savebpHandler = function ()
	DDebuger:SaveBreakPoint()
end

local breakHandler = function (paramList)
	DDebuger:SetBreadkPoint(paramList)
end

DDebuger.HandlerList = {
	["quit"] = quitHandler,
	["q"] = quitHandler,
	["print"] = printHandler,
	["p"] = printHandler,
	["next"] = nextHandler,
	["n"] = nextHandler,
	["save"] = savebpHandler,
	["s"] = savebpHandler,
	["break"] = breakHandler,
	["b"] = breakHandler,
}
------------------------HandlerList end----------------------

------------------------DataList beg-------------------------
DDebuger.localTabel = {}
DDebuger.upvalueTable = {}
------------------------DataList end-------------------------

-- 分割字符串
local function SplitString(paramStr, splitChar)
	local subStr = {}
	if paramStr then
		while true do
			local i = string.find(paramStr, splitChar)
			if not i then
				break
			end
			table.insert(subStr, string.sub(paramStr, 1, i-1))
			paramStr = string.sub(paramStr, i+1)
		end
	end
	return subStr
end

-- 解析调试接收数据
function ParseMessage(data)
	local paramList = {}
	local commandBeg, commandEnd, command = string.find(data, "(%a+)|")
	if not command then
		return 
	end

	local paramSource = string.sub(data, commandEnd+1)
	if paramSource then
		paramList = SplitString(paramSource, "|")
	end

	return command, paramList
end

-- 初始化local变量
function DDebuger:InitLocalTableLua(level)
	DDebuger.localTabel = {}

	local n = 1
	while true do
		local key, value = debug.getlocal(level, n)
		if not key then 
			break
		end
		if value == nil then
			value = "nil"
		end
		DDebuger.localTabel[key] = value
		n = n + 1
	end
end

-- 初始化upvalue变量
function DDebuger:InitUpvalueTableLua(level)
	DDebuger.upvalueTable = {}

	local info = debug.getinfo(level, "nf")
	local func = info.func

	local n = 1
	while true do
		local key, value = debug.getupvalue(func, n)
		if not key then 
			break
		end
		if value == nil then
			value = "nil"
		end
		DDebuger.upvalueTable[key] = value
		n = n + 1
	end
end

-- 获取local和upvalue变量
function DDebuger.GetLocalAndUpValueLua(key)
	local resultList = {}
	if DDebuger.localTabel 
		and DDebuger.localTabel[key] then

		table.insert(resultList, "local(key == value): " .. key .. " == " .. DDebuger.localTabel[key])

	end
	if DDebuger.upvalueTable 
		and DDebuger.upvalueTable[key] then

		table.insert(resultList, "upvalue(key == value): " .. key .. " == " .. DDebuger.upvalueTable[key])

	end
	return resultList
end

-- 调试命令处理
function DDebuger:HandlerMessage(data)
	if not data then
		return
	end
	local command, paramList = ParseMessage(data)
	if not command then
		return 
	end
	if not DDebuger.HandlerList[command] then
		return 
	end

	DDebuger.HandlerList[command](paramList)
end

-- 进入调试模式
function DDebuger:EnterDebug(info)
	if not info then
		return 
	end

	if not self.conn then
		return 
	end

	-- 初始化变量信息
	local level = self:GetDebugLevel()
	self:InitLocalTableLua(level+1)
	self:InitUpvalueTableLua(level+1)

	-- 中断运行并等待调试命令
	self:Print("[DDebuger] EnterDebug!!", info.short_src, info.currentline)
	self.isBreak = true
	self.isSingleStep = false
	while true do
		if not self.isBreak then
			self:Print("[DDebuger] QuitDebug!!")
			break
		end
		local data, e = self.conn:receive() --接收
		if data and e ~= "closed" then
			self:HandlerMessage(data)
		else
			self.conn:close()
			self.conn = nil
		end
	end
end

-- 用于判断时候是本文件调用
function DDebuger:CheckSelfFunc(info)
	if not info then
		return true
	end

	if not self.short_src then
		return true
	end

	if info.short_src == self.short_src then
		return true
	end

	return false
end

-- 记录当前文件信息
function DDebuger:InitSourcePath()
	local info = debug.getinfo(1, "S")
	if not info then
		return false
	end
	self.short_src = info.short_src
	return true
end

-- 初始化输入输出
function DDebuger:InitDisplayModule()
	local socket = require"socket"
	local host = "127.0.0.1"
	local port = "6000"
	self.sever = assert(socket.bind(host, port)) --绑定
	self.sever:settimeout(nil)   --不设置阻塞

	local connList = {}
	table.insert(connList, self.sever)

	os.execute([[ start E:\\DDebugger\\ddebuggerC\\DDebuggerC.exe ]])

	while true do 
		self.conn = self.sever:accept()  --连接
		if self.conn then
			self.conn:send("[DDebuger] Connect DDebugerMoudle Suc!!!")
			break 
		end	
	end
end

-- 获取堆栈level
function DDebuger:GetDebugLevel()
	local info
	local level = 2
	while level < 10 do
		local info = debug.getinfo(level, "lS")
		if not self:CheckSelfFunc(info) then
			level = level - 1
			break
		end
		level = level + 1
	end
	return level
end

-- 发送数据显示
function DDebuger:Print( ... )
	local arg = { ... }
	local content = ""
	for k, v in pairs(arg) do
		content = content .. v .. "\t"
	end
	content = content

	if self.conn then
		self.conn:send(content)
	end
end

-- 启动调试功能
function DDebuger:DOpenDebug()
	self.isOpen = true

	self:InitDisplayModule()

	if not self:InitSourcePath() then
		error("初始化本文件信息失败")
		return 
	end

	-- 初始化断点列表
	self:LoadBreakPoint()

	local hookFunc = function ()
		-- 获取当前的调试信息
		local info = debug.getinfo(2, "nlS")
		if not info then
			return
		end
		-- 过滤该文件的hook
		if self:CheckSelfFunc(info) then
			return 
		end
		-- 判断是否击中断点
		if not self.isSingleStep and not self:CheckHitBreakPoint(info) then
			return 
		end
		-- 进入调试模式
		self:EnterDebug(info)
	end
	debug.sethook(hookFunc, "l")
end

-- 判断是否击中断点
function DDebuger:CheckHitBreakPoint(info)
	if not info then
		return 
	end
	if not self.bpList then
		return 
	end
	local _, _, short_src = string.find(info.short_src, [[\(%a+).lua]])
	if not short_src then
		return 
	end
	if not self.bpList[short_src] then
		return 
	end
	if not self.bpList[short_src][tostring(info.currentline)] then
		return 
	end

	return true
end

function DDebuger:SetBreadkPoint(paramList)
	local short_src = tostring(paramList[1])
	local line = tostring(paramList[2])

	if not self.bpList[short_src] then
		self.bpList[short_src] = {}
	end
	self.bpList[short_src][line] = true
	self:Print("[DDebuger] SetBreadkPoint Suc: ", short_src, line)
end

-- 加载断点信息
function DDebuger:LoadBreakPoint()
	self.bpList = {}

	if not bpFile then
		self:Print("[error] Can not find bp file!")
		return 
	end

	local f = assert(io.open(bpFile,'r'))
	if f then
		for content in f:lines() do
			self:Print("[DDebuger] Load pb item: ", content)
			local subStr = SplitString(content, "|")
			local lineList = {}
			for i = 2, #subStr do
				lineList[subStr[i]] = true
			end
			self.bpList[subStr[1]] = lineList
		end
	end

	self:Print("[DDebuger] Load pb done!", content)
	f:close()
end

-- 保存断点信息
function DDebuger:SaveBreakPoint()
	if not self.bpFile then
		return 
	end

	if not bpFile then
		error("断点信息文件路径未空")
		return 
	end

	local f = assert(io.open(bpFile,'w'))
	if f then
		local content = ""
		for short_src, lineList in ipairs(self.bpFile) do
			content = content .. short_src .. "|"
			for k, v in pairs(lineList) do
				content = content .. k .. "|"
			end
			content = content .. "\n\r"
		end

		self:Print("[DDebuger] Save bp info:", content)

		f:write(content)
	    f:close()
	end 
end
