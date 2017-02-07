--[[
    Based on:
	LUA variant of the php unserialize function
	Port of http://phpjs.org/functions/unserialize
	https://gist.github.com/cristobal/3647759
	and
	crowdlab/js-php-unserialize
	https://github.com/crowdlab/js-php-unserialize
]]--

local unserializer = {}

local function utf8Overhead(chr)
    local code = chr:byte()
    if (code < 0x0080) then
        return 0
    end

    if (code < 0x0800) then
        return 1
    end

    return 2
end

local function readUntil(data, offset, stopchr)
    local buf, chr, len

    buf = {}
    chr = data:sub(offset, offset)
    len = string.len(data)
    while (chr ~= stopchr) do
        if (offset > len) then
            error('Error', 'Invalid')
        end
        table.insert(buf, chr)
        offset = offset + 1

        chr = data:sub(offset, offset)
    end

    return {table.getn(buf), table.concat(buf,'')}
end

local function readChrs(data, offset, length)
    local i, buf
    buf = {}
    for i = 0, length - 1, 1 do
        local chr = data:sub(offset + i, offset + i)
        table.insert(buf, chr)

        length = length - utf8Overhead(chr)
    end
    return {table.getn(buf), table.concat(buf,'')}
end


local function _unserialize(data, offset)
    local dtype, dataoffset, keyandchrs, keys
    local readdata, readData, ccount, stringlength
    local i, key, kprops, kchrs, vprops, vchrs, value, chrs, typeconvert
    local chrs = 0
    typeconvert = function(x) return x end

    if offset == nil then
        offset = 1 -- lua offsets starts at 1
    end

    dtype = string.lower(data:sub(offset, offset))

    dataoffset = offset + 2
    if (dtype == 'i') or (dtype == 'd') then
        typeconvert = function(x)
            return tonumber(x)
        end

        readData = readUntil(data, dataoffset, ';')
        chrs     = tonumber(readData[1])
        readdata = readData[2]
        dataoffset = dataoffset + chrs + 1

    elseif dtype == 'b' then
        typeconvert = function(x)
            return tonumber(x) ~= 0
        end

        readData = readUntil(data, dataoffset, ';')
        chrs 	 = tonumber(readData[1])
        readdata = readData[2]
        dataoffset = dataoffset + chrs + 1
    elseif dtype == 'n' then
        readData = nil

    elseif dtype == 's' then
        ccount = readUntil(data, dataoffset, ':')

        chrs         = tonumber(ccount[1])
        stringlength = tonumber(ccount[2])
        dataoffset = dataoffset + chrs + 2

        readData = readChrs(data, dataoffset, stringlength)
        chrs     = readData[1]
        readdata = readData[2]
        dataoffset = dataoffset + chrs + 2

        if ((chrs ~= stringlength) and (chrs ~= string.length(readdata.length))) then
            error('SyntaxError', 'String length mismatch')
        end

    elseif dtype == 'a' then
        readdata = {}

        keyandchrs = readUntil(data, dataoffset, ':')
        chrs = tonumber(keyandchrs[1]);
        keys = tonumber(keyandchrs[2]);

        dataoffset = dataoffset + chrs + 2

        for i = 0, keys - 1, 1 do
            kprops = _unserialize(data, dataoffset);

            kchrs  = tonumber(kprops[2])
            key    = kprops[3]
            dataoffset = dataoffset + kchrs

            vprops = _unserialize(data, dataoffset)
            vchrs  = tonumber(vprops[2])
            value  = vprops[3]
            dataoffset = dataoffset + vchrs

            readdata[key] = value
        end

        dataoffset = dataoffset + 1
    elseif dtype == 'c' then
        ccount = readUntil(data, dataoffset, ':')

        chrs         = tonumber(ccount[1])
        stringlength = tonumber(ccount[2])
        dataoffset = dataoffset + chrs + 2

        readData = readChrs(data, dataoffset, stringlength)
        chrs     = readData[1]
        readdata = readData[2]
        dataoffset = dataoffset + chrs + 2

        ccount = readUntil(data, dataoffset, ':')

        chrs         = tonumber(ccount[1])
        stringlength = tonumber(ccount[2])
        dataoffset = dataoffset + chrs + 2

        readData = readChrs(data, dataoffset, stringlength)
        chrs     = readData[1]
        readdata = readdata  .. '|' .. readData[2]
        dataoffset = dataoffset + chrs + 1
    else
        error('SyntaxError', 'Unknown / Unhandled data type(s): ' + dtype);
    end

    return {dtype, dataoffset - offset, typeconvert(readdata)}
end

local function _unserializeSession(data)
    local pos = 1
    local result = {}

    if data == '' then
        return nil
    end

    repeat
        local key = ''
        local c = data:sub(pos, pos)

        while (string.len(data) >= pos and c ~= '|') do
            key = key .. c
            pos = pos + 1
            c = data:sub(pos, pos)
        end

        if key == '' or key == "\n" or key == "\r" then
            break
        end
        pos = pos + 1

        local r = _unserialize(data, pos)

        if not r or r[2] == 0 then
            return nil
        end
        pos = pos + r[2]
        result[key] = r[3]
    until pos >= string.len(data)

    return result
end


function unserializer.unserialize(data)
    local result = _unserialize(data or "", 1)
    if result ~= nil then
        return result[3]
    end
    return nil
end

function unserializer.unserializeSession(data)
    return _unserializeSession(data)
end

return unserializer