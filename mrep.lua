local imgui = require 'mimgui'
local encoding = require 'encoding'
local sampev = require 'samp.events'
local inicfg = require 'inicfg'
local ffi = require 'ffi'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Настройки обновления
local script_version = 3
local update_url = "https://raw.githubusercontent.com/molux1/mrep-yava/main/version.json"
local script_url = "https://raw.githubusercontent.com/molux1/mrep-yava/main/mrep.lua"

-- Конфигурация
local config_path = getWorkingDirectory() .. "\\config\\MREP-Yava.ini"
local mainIni = inicfg.load({
    settings = {
        token = "",
        chat_id = ""
    }
}, config_path)

local win_state = imgui.new.bool(false)
local vk_token = imgui.new.char[256](mainIni.settings.token)
local vk_chat_id = imgui.new.char[64](mainIni.settings.chat_id)

-- Снежинки
local snowflakes = {}
for i = 1, 60 do
    snowflakes[i] = {
        x = math.random(0, 1920), -- примерное ограничение, в OnFrame адаптируется
        y = math.random(0, 1080),
        speed = math.random(10, 30) / 100,
        size = math.random(1, 2)
    }
end

function apply_ny_style()
    local style = imgui.GetStyle()
    style.WindowRounding = 10.0
    style.FrameRounding = 4.0
    style.Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.06, 0.06, 0.07, 0.94)
    style.Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.Button] = imgui.ImVec4(0.16, 0.17, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.25, 0.26, 0.30, 1.00)
    style.Colors[imgui.Col.Text] = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
end

function HelpMarker(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 35.0)
        imgui.TextUnformatted(u8(text))
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

imgui.OnFrame(function() return win_state[0] end, function()
    apply_ny_style()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(480, 380), imgui.Cond.FirstUseEver)
    
    imgui.Begin(u8"* Mrep 1111Arizona RP Yava | New Year Edition *", win_state, imgui.WindowFlags.NoResize)
    
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetWindowPos()
    local s = imgui.GetWindowSize()
    local sn_col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.3))
    for i, f in ipairs(snowflakes) do
        f.y = f.y + f.speed
        if f.y > s.y then f.y = -5 end
        dl:AddCircleFilled(imgui.ImVec2(p.x + f.x, p.y + f.y), f.size, sn_col)
    end

    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"Автор данного скрипта - Severin_Starlink - Администратор Arizona RP Yava")
    imgui.Separator()
    imgui.Spacing()

    if imgui.Button(u8"[*] ПОЛУЧИТЬ TOKEN (VK ADMIN)", imgui.ImVec2(-1, 35)) then
        os.execute("explorer https://vkhost.github.io/")
    end
    HelpMarker("Нажмите на кнопку, на сайте выберите VK Admin и разрешите доступ. Токен будет в ссылке.")

    imgui.Spacing()
    imgui.Text(u8"Access Token:")
    imgui.InputText("##token", vk_token, 256)
    HelpMarker("Ключ доступа от VK Admin.")

    imgui.Spacing()
    imgui.Text(u8"ID Беседы:")
    imgui.InputText("##chatid", vk_chat_id, 64)
    HelpMarker("Число после convo/ в адресной строке браузера там где курилка.")

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    if imgui.Button(u8"[*] ЗАМОРОЗИТЬ НАСТРОЙКИ [*]", imgui.ImVec2(-1, 40)) then
        mainIni.settings.token = ffi.string(vk_token)
        mainIni.settings.chat_id = ffi.string(vk_chat_id)
        inicfg.save(mainIni, config_path)
        sampAddChatMessage(":snowflake: {808080}[VK NY]{FFFFFF} Настройки заморожены! С Новым Годом! :snowflake:", -1)
    end

    imgui.SetCursorPosY(imgui.GetWindowSize().y - 30)
    imgui.TextDisabled(u8"Команда: !mrep [Ник] [Текст] | Arizona Yava | v" .. script_version)
    imgui.End()
end)

-- Функция проверки обновлений
function checkUpdates()
    lua_thread.create(function()
        local path = getWorkingDirectory() .. "\\mrep_ver.tmp"
        downloadUrlToFile(update_url, path)
        
        local stop = os.clock() + 3.0
        while not doesFileExist(path) and os.clock() < stop do wait(10) end
        
        if doesFileExist(path) then
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                os.remove(path)
                
                -- Если в version.json просто число, например: 2
                local new_version = tonumber(content:match("%d+"))
                if new_version and new_version > script_version then
                    sampAddChatMessage("{808080}[VK NY]{FFFFFF} Найдено обновление! Скрипт обновляется...", -1)
                    updateScript()
                end
            end
        end
    end)
end

-- Функция загрузки нового файла
function updateScript()
    lua_thread.create(function()
        local download_path = thisScript().path .. ".tmp"
        downloadUrlToFile(script_url, download_path)
        
        local stop = os.clock() + 5.0
        while not doesFileExist(download_path) and os.clock() < stop do wait(10) end
        
        if doesFileExist(download_path) then
            local f = io.open(download_path, "r")
            if f then
                local content = f:read(10)
                f:close()
                if content then
                    os.rename(download_path, thisScript().path)
                    sampAddChatMessage("{808080}[VK NY]{FFFFFF} Скрипт успешно обновлен! Перезагрузка...", -1)
                    thisScript():reload()
                end
            end
        else
            sampAddChatMessage("{FF4444}[VK Error]{FFFFFF} Не удалось скачать обновление.", -1)
        end
    end)
end

function main()
    while not isSampAvailable() do wait(100) end
    
    -- Запуск проверки обновлений при старте
    checkUpdates()

    sampRegisterChatCommand("vkset", function() win_state[0] = not win_state[0] end)
    math.randomseed(os.time())
    wait(-1)
end

function sampev.onSendChat(message)
    if message:find("^!mrep") then
        local t = mainIni.settings.token
        local c = mainIni.settings.chat_id
        if t ~= "" and c ~= "" then
            sendToVK(t, c, message)
        else
            sampAddChatMessage("{FF0000}[Ошибка]{FFFFFF} Настройте скрипт в /vkset!", -1)
        end
        return false 
    end
end

function sendToVK(token, chat_id, full_text)
    lua_thread.create(function()
        local utf_text = u8:encode(full_text, "UTF8")
        
        local url = string.format("https://api.vk.com/method/messages.send?peer_id=%s&message=%s&random_id=%d&access_token=%s&v=5.131",
            chat_id, urlencode(utf_text), math.random(100000, 999999), token)
        
        local path = getWorkingDirectory() .. "\\vk_last.tmp"
        downloadUrlToFile(url, path)
        
        local stop = os.clock() + 3.0
        while not doesFileExist(path) and os.clock() < stop do wait(10) end
        
        if doesFileExist(path) then
            wait(50)
            local f = io.open(path, "rb")
            if f then
                local content = f:read("*all")
                f:close()
                os.remove(path)
                if content:find('"response":') then
                    sampAddChatMessage("{808080}[VK]{FFFFFF} Ваше обращение отправлено в ВК Курилку! :arz:", -1)
                else
                    sampAddChatMessage("{FF4444}[VK Error]{FFFFFF} Ошибка API! Проверьте токен или ID.", -1)
                end
            end
        else
            sampAddChatMessage("{FF4444}[VK Error]{FFFFFF} Нет связи с ВК. Проверьте VPN.", -1)
        end
    end)
end

function urlencode(str)
    if str then
        str = str:gsub("\n", "\r\n")
        str = str:gsub("([^%w %-%_%.%~])", function(c) return ("%%%02X"):format(string.byte(c)) end)
        str = str:gsub(" ", "+")
    end
    return str
end