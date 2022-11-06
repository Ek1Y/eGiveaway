RegisterNetEvent("openDialogCreate")
AddEventHandler("openDialogCreate", function()
    local input = lib.inputDialog(_U('title'), {
        { type = "input", label = _U('code'), placeholder = "EkY-XXXXXXXX" },
        { type = "number", label = _U('maxUse'), default = 1 },
        { type = "input", label = _U('reward') },
        { type = "number", label = _U('quantity'), default = 1 }
    })

    if input == nil then return end

    ESX.TriggerServerCallback('eGiveaway:createGiveaway', function(cb, code)
        if cb == 'success' then
            ESX.ShowNotification(_U('insert_success'))
            print('Code: ' .. code)
        elseif cb == 'updated' then
            ESX.ShowNotification(_U('updated'))
        else
            ESX.ShowNotification(_U('insert_failed'))
        end
    end, input)
end)

RegisterNetEvent("openDialogRedeem")
AddEventHandler("openDialogRedeem", function()
    local input = lib.inputDialog(_U('redeem'), {
        { type = "input", label = _U('code_redeem'), placeholder = 'EkY-XXXXXXXX' },
    })

    ESX.TriggerServerCallback('eGiveaway:redeemGiveaway', function(cb)
        if cb == 'success' then
            ESX.ShowNotification(_U('redeem_success'))
        elseif cb == 'empty' then
            ESX.ShowNotification(_U('empty'))
        elseif cb == 'format' then
            ESX.ShowNotification(_U('format'))
        elseif cb == 'not_exist' then
            ESX.ShowNotification(_U('not_exist'))
        elseif cb == 'limit' then
            ESX.ShowNotification(_U('limit'))
        elseif cb == 'full' then
            ESX.ShowNotification(_U('full'))
        end
    end, input)
end)