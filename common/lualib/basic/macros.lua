-- 全局常量根节点
if GLOBAL == nil then
    GLOBAL = {}
end

-- 数据仓库枚举
GLOBAL.DB = 
{
    UNKNOWN = 0,
    FSDISK  = 1,
    REDIS   = 2,
    MONGO   = 3,
    MYSQL   = 4,
}

GLOBAL.SERVICE_NAME =
{
    SUMMD       = ".summd",
    GATED       = ".gated",
    RELAY       = ".relay",
    DATABASED   = "DATABASE",
    DATACACHED  = "DATACACHE",
    USERCENTERD = "USERCENTER",
    GAME        = ".game",
    ROOM        = ".room",
}

GAME = 
{
    ---------------------------------------------
    -- 业务数据类型枚举
    ---------------------------------------------
    META =
    {
        -- 角色相关数据类型
        PLAYER        = 10,    -- 角色信息
    },
}
