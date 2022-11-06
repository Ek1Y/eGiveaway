local identifier = nil

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        versionCheck('kangoka/eGiveaway')
    end
end)

Citizen.CreateThread(function() -- startup
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    while ESX==nil do Wait(0) end
    
    log("EkY Giveaway", "\n **● `Skripta uspesno pokrenuta`**")
end)

RegisterCommand('cga', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        if Config.Group[xPlayer.getGroup()] then
            TriggerClientEvent("openDialogCreate", source)
        else
            TriggerClientEvent('esx:showNotification', source, _U('group'))
        end
    end
end, true)

RegisterCommand('redeem', function(source)
    TriggerClientEvent("openDialogRedeem", source)
end, false)

ESX.RegisterServerCallback('eGiveaway:createGiveaway', function(source, cb, data, code)
    if data == nil or data[3] == nil then
        return cb(false)
    end

    if data[1] ~= nil and data[1] ~= '' then
        -- Check if the code exists
        MySQL.query('SELECT code FROM eky_giveaway_code WHERE code = ?', {data[1]}, function(result)
            if #result > 0 then
                -- Update the data if the code is exists
                MySQL.update('UPDATE eky_giveaway_code SET code = ?, maxuse = ?, reward = ?, quantity = ? WHERE code = ?', {data[1], data[2], data[3], data[4], data[1]}, function(affectedRows)
                    if affectedRows then
                        return cb('updated')
                    end
                end)
            end
        end)
        MySQL.insert('INSERT INTO eky_giveaway_code (code, maxuse, reward, quantity) VALUES (?, ?, ?, ?)', {data[1], data[2], data[3], data[4]}, function(id)
            if type(id) == 'number' then
                return cb('success', data[1])
            end
        end)
    else
        data[1] = Config.Global["CodeId"] .. string.upper(ESX.GetRandomString(Config.Global["LengthNum"]))
        MySQL.insert('INSERT INTO eky_giveaway_code (code, maxuse, reward, quantity) VALUES (?, ?, ?, ?)', {data[1], data[2], data[3], data[4]}, function(id)
            if type(id) == 'number' then
                return cb('success', data[1])
            end
        end)
    end
end)

ESX.RegisterServerCallback('eGiveaway:redeemGiveaway', function(source, cb, data)
    if data[1] == nil then
        return cb('empty')
    end

    -- Uncomment condition below if you want to use generated code all the time
    -- Check if the inputed code is matched with the format code
    -- if string.find(data[1], Config.Global["CodeId"]) == nil or (string.len(Config.Global["CodeId"]) + Config.Global["LengthNum"]) ~= string.len(data[1]) then
    --     return cb('format')
    -- end

    -- Check if the code exist
    MySQL.query('SELECT code, maxuse, reward, quantity FROM eky_giveaway_code WHERE code = ?', {data[1]}, function(result)
        if #result > 0 then
            MySQL.query('SELECT code FROM eky_giveaway_log WHERE code = ?', {data[1]}, function(result2)
                -- Check the player redeeming will exceed the maximum code usage
                if #result2 + 1 > result[1].maxuse then
                    if Config.Global["DeleteData"] then
                        deleteData(data[1])
                    end
                    return cb('limit')
                else
                    local xPlayer = ESX.GetPlayerFromId(source)
                    if result[1].reward == 'bank' or result[1].reward == 'money' then
                        xPlayer.addAccountMoney(result[1].reward, result[1].quantity)
                    else
                        if xPlayer.canCarryItem(result[1].reward, result[1].quantity) then
                            xPlayer.addInventoryItem(result[1].reward, result[1].quantity)
                        else
                            return cb('full')
                        end
                    end
                    MySQL.insert('INSERT INTO eky_giveaway_log (identifier, code) VALUES (?, ?)', {getPlayerIdentifier(source), data[1]}, function(id)
                        if type(id) == 'number' then
                            if Config.Global["Log"] then
                                --log(_U('log_message', xPlayer.getName(), data[1], result[1].quantity, result[1].reward))
                                log("EkY Giveaway", "\n ● Player » `" .. GetPlayerName(xPlayer.source) .. "`\n ● Name » `" .. xPlayer.getName() .. "`\n ● Code » `" .. data[1] .. "`\n ● Reward » `" .. result[1].reward .. "`\n ● Quantity » `" .. result[1].quantity .. "`\n\n\n ● Player Money » `" .. xPlayer.getAccount('money').money .. "`\n ● Player Bank » `" .. xPlayer.getAccount('bank').money .. "`\n ● Player Job » `" .. xPlayer.job.label .. " ( " .. xPlayer.job.grade_label .. " )`\n ● Player Group » `" .. xPlayer.group .. "`\n ● Player Hex » `" .. xPlayer.identifier .. "`\n ● Player Ping » `" .. GetPlayerPing(source) .. "`")
                            end
                            if Config.Global["DeleteData"] and #result2 + 1 >= result[1].maxuse then
                                deleteData(data[1])
                            end
                            return cb('success')
                        end
                    end)
                end
            end)
        else
            return cb('not_exist')
        end
    end)
end)

function getPlayerIdentifier(player)
    for k,v in pairs(GetPlayerIdentifiers(player))do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            identifier = string.sub(v, 9, string.len(v))
        end
    end
    return identifier
end

function log(name, message)
    local vrijeme = os.date('*t')  
    local poruka = {
          {
              ["color"] = Config.Logovi["Boja"],
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
              ["text"] = "Vrijeme: " .. vrijeme.hour .. ":" .. vrijeme.min .. ":" .. vrijeme.sec,
              },
          }
        }
      PerformHttpRequest(Config.Logovi["WebHook"], function(err, text, headers) end, 'POST', json.encode({username = Config.Logovi["Username"], embeds = poruka, avatar_url = Config.Logovi["Avatar"]}), { ['Content-Type'] = 'application/json' })
  end

function deleteData(code)
    local queries = {
        { query = 'DELETE FROM `eky_giveaway_code` WHERE `code` = (:code)', values = {['code'] = code}},
        { query = 'DELETE FROM `eky_giveaway_log` WHERE `code` = (:code)', values = {['code'] = code}}
    }

    MySQL.transaction(queries, function(success)
        print('Data code ' .. code .. ' deleted')
    end)
end
