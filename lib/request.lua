local response = require "ccdp.lib.response"
_CCDP_VERSION = "0.0.1"
_CCDP_TIME_OUT = 10

local RequestType = {
    GET = "GET",
    SET = "SET",
    DEL = "DEL",
    CREATE = "CREATE",
}

local Request = {
    mt = {
        __name = "ccdp.request",
    }
}
---@param addr string
---@param ty string
---@param content table<string, any>
---@param info table<string, any>
function Request.new(addr, ty, content, info)
    if not RequestType[ty] then
        error(("bad argument #2 (invalid request type %q)"):format(ty), 2)
    end
    ---@class ccdp.request
    return setmetatable({
        addr = addr,
        ty = ty,
        content = content,
        info = info,

        tostring = Request.tostring,
        totable = Request.totable,
        tojson = Request.tojson,
    }, Request.mt)
end
---@param value any
---@return ccdp.request|nil
function Request.from(value)
    if type(value) == "string" then
        return Request.fromstring(value)
    elseif type(value) == "table" then
        if not value.addr then
            return nil
        end
        if not value.ty then
            return nil
        end
        if not RequestType[value.ty] then
            return nil
        end
        return Request.new(value.addr, value.ty, value.content, value.info)
    else
        return nil
    end
end
---@param message string
---@return ccdp.request|nil
function Request.fromstring(message)
    local addr, ty = message:match("^CCDP ([^ ]+) ([^ \\n]+)")
    if not addr then
        return nil
    end
    local content = {}
    local info = {}
    local content_string, info_string = message:match("\\n\\n(.*)\\n\\n(.*)\\n\\n$")
    if content_string then
        for k, v in content_string:gmatch("([^:]+): ([^\\n]+)\\n") do
            content[k] = v
        end
    end
    if info_string then
        for k, v in info_string:gmatch("([^:]+): ([^\\n]+)\\n") do
            info[k] = v
        end
    end
    return Request.new(addr, ty, content, info)
end
---@param self ccdp.request
function Request:tostring()
    local content_string = ""
    if self.content then
        for k, v in pairs(self.content) do
            content_string = content_string .. ("%s: %q\n"):format(k, v)
        end
    end
    local info_string = ""
    if self.info then
        for k, v in pairs(self.info) do
            info_string = info_string .. ("%s: %q\n"):format(k, v)
        end
    end
    return ("CCDP %q %s\n\n%s\n\n%s\n\n"):format(self.addr, self.ty, content_string, info_string)
end
Request.mt.__tostring = Request.tostring
---@param self ccdp.request
function Request:totable()
    return {
        addr = self.addr,
        ty = self.ty,
        content = self.content,
        info = self.info,
    }
end
---@param self ccdp.request
function Request:tojson()
    return textutils.serialize(self:totable())
end

return {
    Request = Request,
    RequestType = RequestType,
    get = function (addr, content, info)
        local request = Request.new(addr, RequestType.GET, content, info)
        rednet.send(addr, request:tostring(), "ccdp")
        local sender, res = rednet.receive("ccdp", _CCDP_TIME_OUT)
        if not sender then
            return nil, "timeout"
        end
        return response.Response.fromstring(res)
    end,
    set = function (addr, content, info)
        local request = Request.new(addr, RequestType.SET, content, info)
        rednet.send(addr, request:tostring(), "ccdp")
        local sender, res = rednet.receive("ccdp", _CCDP_TIME_OUT)
        if not sender then
            return nil, "timeout"
        end
        return response.Response.fromstring(res)
    end,
    del = function (addr, content, info)
        local request = Request.new(addr, RequestType.DEL, content, info)
        rednet.send(addr, request:tostring(), "ccdp")
        local sender, res = rednet.receive("ccdp", _CCDP_TIME_OUT)
        if not sender then
            return nil, "timeout"
        end
        return response.Response.fromstring(res)
    end,
    create = function (addr, content, info)
        local request = Request.new(addr, RequestType.CREATE, content, info)
        rednet.send(addr, request:tostring(), "ccdp")
        local sender, res = rednet.receive("ccdp", _CCDP_TIME_OUT)
        if not sender then
            return nil, "timeout"
        end
        return response.Response.fromstring(res)
    end,
}