---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by dengcs.
--- DateTime: 2018/11/26 14:17
---
local skynet        = require "skynet"
local service       = require "factory.service"
local socketchannel = require "skynet.socketchannel"
local pbhelper      = require "net.pbhelper"

local server = {}
local CMD = {}

local strpack           = string.pack
local strunpack         = string.unpack
local sky_packstring    = skynet.packstring

local encode = pbhelper.pb_encode
local decode = pbhelper.pb_decode

local channel = nil
local reply_id = 1

local function dispatch_reply(so)
    local len_reply	= so:read(2)
    len_reply = strunpack(">H", len_reply)
    local reply	= so:read(len_reply)

    local result = skynet.unpack(reply)

    if result then
        local fd        = result.header.fd
        local protoName = result.header.proto
        local data      = result.payload
        local errCode   = result.error.code
        local msgData = encode(protoName, data, errCode)
        skynet.send(GLOBAL.SERVICE_NAME.GATED, "lua", "response", fd, msgData)
    end

    return reply_id
end

function CMD.forward(fd, msg)
    if channel then
        local msgData = decode(msg)
        if msgData then
            msgData.header.fd = fd
            local msg_data = sky_packstring(msgData)
            local msg_len = strpack(">H", msg_data:len())
            local compose_data = {msg_len, msg_data}
            local packet_data = table.concat(compose_data)

            channel:request(packet_data)
        end
    end
end

function CMD.transmit(fd, protoName)
    if channel then
        local msgData =
        {
            header =
            {
                fd      = fd,
                cmd     = true,
                proto   = protoName,
            }
        }
        local msg_data = sky_packstring(msgData)
        local msg_len = strpack(">H", msg_data:len())
        local compose_data = {msg_len, msg_data}
        local packet_data = table.concat(compose_data)

        channel:request(packet_data)
    end
end

function server.init_handler()
    pbhelper.register()

    channel = socketchannel.channel {
        host        = "127.0.0.1",
        port        = 51001,
        nodelay     = true,
        response    = dispatch_reply,
    }

    if not channel then
        ERROR(ENETUNREACH, "channel is nil")
        return
    end

    channel:connect(true)
end

function server.exit_handler()
end

function server.command_handler(source, cmd, ...)
    local fn = CMD[cmd]
    if fn then
        return fn(...)
    else
        ERROR(EFAULT, "call: %s: command not found", cmd)
    end
end

service.start(server)