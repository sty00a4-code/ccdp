local ResponseType = {
    OK = "OK",
    ERROR = "ERROR",
    INFO = "INFO",
    UNKNOWN = "UNKNOWN",
}

local Response = {
    mt = {
        __name = "ccdp.response",
    }
}
---@param addr string
---@param ty string
---@param content table<string, any>
---@param info table<string, any>
function Response.new(addr, ty, content, info)
    if not ResponseType[ty] then
        error(("bad argument #2 (invalid response type %q)"):format(ty), 2)
    end
    ---@class ccdp.response
    return setmetatable({
        addr = addr,
        ty = ty,
        content = content,
        info = info,

        tostring = Response.tostring,
        totable = Response.totable,
        tojson = Response.tojson,
    }, Response.mt)
end
---@param value any
---@return ccdp.response|nil
function Response.from(value)
    if type(value) == "string" then
        return Response.fromstring(value)
    elseif type(value) == "table" then
        if not value.addr then
            return nil
        end
        if not value.ty then
            return nil
        end
        if not ResponseType[value.ty] then
            return nil
        end
        return Response.new(value.addr, value.ty, value.content, value.info)
    else
        return nil
    end
end
---@param message string
---@return ccdp.response|nil
function Response.fromstring(message)
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
    return Response.new(addr, ty, content, info)
end
---@param self ccdp.response
function Response:tostring()
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
Response.mt.__tostring = Response.tostring
---@param self ccdp.response
function Response:totable()
    return {
        addr = self.addr,
        ty = self.ty,
        content = self.content,
        info = self.info,
    }
end
---@param self ccdp.response
function Response:tojson()
    return textutils.serialize(self:totable())
end

return {
    Response = Response,
    ResponseType = ResponseType,
    ok = function(addr, content, info)
        local response = Response.new(addr, ResponseType.OK, content, info)
        rednet.send(addr, tostring(response))
    end,
    error = function(addr, content, info)
        local response = Response.new(addr, ResponseType.ERROR, content, info)
        rednet.send(addr, tostring(response))
    end,
    info = function(addr, content, info)
        local response = Response.new(addr, ResponseType.INFO, content, info)
        rednet.send(addr, tostring(response))
    end,
    unknown = function(addr, content, info)
        local response = Response.new(addr, ResponseType.UNKNOWN, content, info)
        rednet.send(addr, tostring(response))
    end,
}