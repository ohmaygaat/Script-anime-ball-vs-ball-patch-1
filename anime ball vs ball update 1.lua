-- Auto Raid & Auto Story + UI
-- RAID : Play > Raids > Vote Boss > Vote Nightmare > Spiral Shemon
-- STORY: Play > Story > HAWKS > Nightmare > QUEUE > START NOW > Spiral Shemon
-- Execute ulang kapan saja: versi lama otomatis dimatikan dan diganti yang baru.
if not game:IsLoaded() then game.Loaded:Wait() end

local __ok, __err = pcall(function()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local function svc(name)
    local ok, r = pcall(function() return game:GetService(name) end)
    return ok and r or nil
end
local VIM = svc("VirtualInputManager")   -- bisa nil di executor tertentu
local VirtualUser = svc("VirtualUser")   -- bisa nil di executor tertentu
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ================= PENGATURAN =================
local CFG = {
    BOSS       = "QUAKEFATHER RAID", -- boss yang di-vote (sesuai video)
    DIFFICULTY = "NIGHTMARE",        -- NORMAL / HARD / NIGHTMARE
    STORY_BOSS = "HAWKS",            -- kartu boss mode STORY
    STORY_DIFF = "NIGHTMARE",        -- difficulty mode STORY
    BALL       = "SPIRAL SHEMON",    -- bola yang dipilih
    SWAP_INDEX = 1,                  -- tombol SWAP BALL ke berapa (1 = paling kiri)
    LOOP       = 1.2,                -- detik antar pengecekan (naikkan kalau HP berat)
    COOLDOWN   = 2.5,                -- jeda minimal antar klik tombol yang sama
    BUSY       = 10,                 -- tahan klik PLAY X detik setelah layar raid terakhir terlihat
}
-- ==============================================

-- Matikan instance lama
local G = (getgenv and getgenv()) or _G -- cadangan kalau executor tidak punya getgenv
if G.AutoRaid then pcall(G.AutoRaid.Destroy) end
local S = { enabled = false, mode = nil, alive = true, status = "Pilih RAID atau STORY", busyUntil = 0 }
G.AutoRaid = S

local conns, last, padPart = {}, {}, nil
local function track(c) table.insert(conns, c); return c end

-- ---------- Anti-AFK ----------
track(player.Idled:Connect(function()
    if not VirtualUser then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

-- ---------- UI ----------
local uiParent
pcall(function() uiParent = (gethui and gethui()) or game:GetService("CoreGui") end)
uiParent = uiParent or PlayerGui

local gui = Instance.new("ScreenGui")
gui.Name = "AutoRaidUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
do
    local okp = pcall(function() gui.Parent = uiParent end)
    if not okp or not gui.Parent then pcall(function() gui.Parent = PlayerGui end) end
end

-- Setiap boss memiliki tingkat kesulitan tersendiri.
local BOSS_OPTIONS = {
    earthquake = { label = "EARTHQUAKE FATHER", vote = "QUAKEFATHER RAID" },
    broly = { label = "BROLY", vote = "BROLY RAID" },
    madara = { label = "MADARA", vote = "MADARA RAID" },
    story = { label = "STORY (HAWKS)" },
}
local DIFFICULTIES = { "NORMAL", "HARD", "NIGHTMARE" }
local bossDifficulty = {
    earthquake = "NIGHTMARE",
    broly = "NIGHTMARE",
    madara = "NIGHTMARE",
    story = "NIGHTMARE",
}

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 292)
frame.Position = UDim2.new(0, 12, 0.5, -146)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(70, 90, 200)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 30)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Text = "HUNTT  |  AUTO RAID"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local rows = {}
local function makeRow(key, y)
    local bossBtn = Instance.new("TextButton")
    bossBtn.Size = UDim2.fromOffset(178, 34)
    bossBtn.Position = UDim2.fromOffset(10, y)
    bossBtn.BackgroundColor3 = Color3.fromRGB(150, 55, 60)
    bossBtn.Text = BOSS_OPTIONS[key].label .. " : OFF"
    bossBtn.Font = Enum.Font.GothamBold
    bossBtn.TextSize = 11
    bossBtn.TextColor3 = Color3.new(1, 1, 1)
    bossBtn.Parent = frame
    Instance.new("UICorner", bossBtn).CornerRadius = UDim.new(0, 8)

    local diffBtn = Instance.new("TextButton")
    diffBtn.Size = UDim2.fromOffset(100, 34)
    diffBtn.Position = UDim2.fromOffset(190, y)
    diffBtn.BackgroundColor3 = Color3.fromRGB(65, 75, 115)
    diffBtn.Text = bossDifficulty[key]
    diffBtn.Font = Enum.Font.GothamBold
    diffBtn.TextSize = 11
    diffBtn.TextColor3 = Color3.new(1, 1, 1)
    diffBtn.Parent = frame
    Instance.new("UICorner", diffBtn).CornerRadius = UDim.new(0, 8)

    rows[key] = { boss = bossBtn, diff = diffBtn }
end

makeRow("earthquake", 42)
makeRow("broly", 82)
makeRow("madara", 122)
makeRow("story", 162)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -20, 0, 30)
statusLbl.Position = UDim2.fromOffset(10, 204)
statusLbl.BackgroundTransparency = 1
statusLbl.TextWrapped = true
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextYAlignment = Enum.TextYAlignment.Center
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 12
statusLbl.TextColor3 = Color3.fromRGB(190, 195, 225)
statusLbl.Parent = frame

local creditLbl = Instance.new("TextLabel")
creditLbl.Size = UDim2.new(1, -20, 0, 20)
creditLbl.Position = UDim2.fromOffset(10, 262)
creditLbl.BackgroundTransparency = 1
creditLbl.Text = "Credit by Huntt"
creditLbl.Font = Enum.Font.GothamBold
creditLbl.TextSize = 11
creditLbl.TextColor3 = Color3.fromRGB(130, 145, 205)
creditLbl.TextXAlignment = Enum.TextXAlignment.Center
creditLbl.Parent = frame

local reopenBtn = Instance.new("TextButton")
reopenBtn.Name = "HunttFloatingButton"
reopenBtn.Size = UDim2.fromOffset(54, 54)
reopenBtn.Position = UDim2.new(0, 16, 0.5, -27)
reopenBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
reopenBtn.Text = "🚗"
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 27
reopenBtn.TextColor3 = Color3.new(1, 1, 1)
reopenBtn.Visible = false
reopenBtn.Parent = gui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(1, 0)
local reopenStroke = Instance.new("UIStroke", reopenBtn)
reopenStroke.Color = Color3.fromRGB(70, 90, 200)
reopenStroke.Thickness = 2

local function refreshUI()
    for key, row in pairs(rows) do
        local active = S.mode == key
        row.boss.Text = BOSS_OPTIONS[key].label .. (active and " : ON" or " : OFF")
        row.boss.BackgroundColor3 = active and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(150, 55, 60)
        row.diff.Text = bossDifficulty[key]
        row.diff.BackgroundColor3 = Color3.fromRGB(65, 75, 115)
    end
    statusLbl.Text = "Status: " .. S.status
end

local function setStatus(t)
    S.status = t
    refreshUI()
end

local function setMode(m)
    -- Tekan 1x = ON (hijau, berjalan). Tekan lagi tombol yang aktif = OFF (merah, berhenti total).
    -- Menekan tombol lain saat ada yang ON: yang lama OFF, yang baru ON.
    S.token = (S.token or 0) + 1 -- membatalkan langkah yang sedang berjalan
    if S.mode == m then
        S.mode = nil
    else
        S.mode = m
    end
    S.enabled = S.mode ~= nil
    S.busyUntil, S.padUntil, S.storyDiffAt = 0, 0, nil
    S.lastVoteUI, S.diffTries, S.bossTries = 0, 0, 0
    last = {}
    if S.mode then
        if S.mode == "story" then
            CFG.STORY_DIFF = bossDifficulty.story
        else
            CFG.BOSS = BOSS_OPTIONS[S.mode].vote
            CFG.DIFFICULTY = bossDifficulty[S.mode]
        end
        setStatus("Berjalan: " .. BOSS_OPTIONS[S.mode].label)
    else
        setStatus("OFF - berhenti")
    end
end

for key, row in pairs(rows) do
    track(row.boss.MouseButton1Click:Connect(function()
        setMode(key)
    end))
    track(row.diff.MouseButton1Click:Connect(function()
        local current = bossDifficulty[key]
        local index = table.find(DIFFICULTIES, current) or 1
        index = (index % #DIFFICULTIES) + 1
        bossDifficulty[key] = DIFFICULTIES[index]
        if S.mode == key then
            if key == "story" then
                CFG.STORY_DIFF = bossDifficulty[key]
                S.storyDiffAt = nil
            else
                CFG.DIFFICULTY = bossDifficulty[key]
            end
        end
        refreshUI()
    end))
end

-- Tombol X menyembunyikan panel; tombol lingkaran membuka kembali.
track(closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    reopenBtn.Visible = true
end))
track(reopenBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    reopenBtn.Visible = false
end))

-- Drag panel dan tombol lingkaran (mouse & sentuh).
local function makeDraggable(handle, target)
    local dragging, startPos, startInput
    track(handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startPos, startInput = true, target.Position, i.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end
makeDraggable(title, frame)
makeDraggable(reopenBtn, reopenBtn)

S.Destroy = function()
    S.alive = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end
refreshUI()

-- ---------- Pembaca layar ----------
local function clean(s)
    s = tostring(s or "")
    s = s:gsub("<[^>]->", ""):upper()
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function isShown(obj)
    local cur = obj
    while cur and cur ~= game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end

-- Cek apakah elemen terpotong di dalam ScrollingFrame
local function isClipped(obj)
    local c = obj.AbsolutePosition + obj.AbsoluteSize / 2
    local cur = obj.Parent
    while cur and not cur:IsA("LayerCollector") do
        if cur:IsA("ScrollingFrame") then
            local p, s = cur.AbsolutePosition, cur.AbsoluteSize
            if c.X < p.X or c.X > p.X + s.X or c.Y < p.Y or c.Y > p.Y + s.Y then return true end
        end
        cur = cur.Parent
    end
    return false
end

-- Satu kali pindai: daftar semua teks yang terlihat
local screen = {}
local function scan()
    local list, count = {}, 0
    local function walk(parent)
        for _, d in ipairs(parent:GetChildren()) do
            if not S.alive then return end
            if d == gui then continue end
            if d:IsA("ScreenGui") and not d.Enabled then continue end
            if d:IsA("GuiObject") and not d.Visible then continue end
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.AbsoluteSize.X > 0 and d.AbsoluteSize.Y > 0 then
                local t = clean(d.Text)
                if t ~= "" and d.TextTransparency < 0.95 then
                    local cam = workspace.CurrentCamera
                    local vp = cam and cam.ViewportSize or Vector2.new(4000, 4000)
                    local c = d.AbsolutePosition + d.AbsoluteSize / 2
                    if c.X > -20 and c.X < vp.X + 20 and c.Y > -60 and c.Y < vp.Y + 60 then
                        table.insert(list, { obj = d, t = t })
                    end
                end
            end
            count += 1
            if count % 250 == 0 then task.wait() end
            walk(d)
        end
    end
    walk(PlayerGui)
    screen = list
end

local function find(text, exact)
    local r = {}
    for _, e in ipairs(screen) do
        if (exact and e.t == text) or (not exact and e.t:find(text, 1, true)) then
            if not isClipped(e.obj) then table.insert(r, e.obj) end
        end
    end
    table.sort(r, function(a, b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
    return r
end
local function has(text, exact) return #find(text, exact) > 0 end

-- Elemen teks `text` (persis) terdekat secara vertikal dengan `label`, di baris yang sama
local function nearestInRow(label, text)
    local cy = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
    local best, bestD
    for _, o in ipairs(find(text, true)) do
        local d = math.abs(o.AbsolutePosition.Y + o.AbsoluteSize.Y / 2 - cy)
        if not bestD or d < bestD then best, bestD = o, d end
    end
    return best, bestD
end

-- ---------- Klik ----------
local function findButton(obj)
    local cur = obj
    while cur and not cur:IsA("LayerCollector") do
        if cur:IsA("GuiButton") then return cur end
        cur = cur.Parent
    end
end

local function click(obj, mode)
    local btn = findButton(obj)
    local fired = false
    if mode ~= "vim" and btn and getconnections then
        for _, sig in ipairs({ "Activated", "MouseButton1Click" }) do
            pcall(function()
                for _, c in ipairs(getconnections(btn[sig])) do
                    c:Fire()
                    fired = true
                end
            end)
            if fired then break end -- cukup satu sinyal, supaya tidak terhitung dua kali
        end
    end
    if not fired and VIM then
        local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
        local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
        local inset = (sg and sg.IgnoreGuiInset) and Vector2.new(0, 0) or GuiService:GetGuiInset()
        VIM:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, false, game, 0)
    end
end

local function press(key, target, cd, mode)
    if not target or not S.mode then return false end
    local now = tick()
    if last[key] and now - last[key] < (cd or CFG.COOLDOWN) then return false end
    last[key] = now
    click(target, mode)
    return true
end

-- ---------- Jalan ke Raid Pad ----------
local padCands = nil

local function collectPads()
    local list, n = {}, 0
    for _, d in ipairs(workspace:GetDescendants()) do
        n += 1
        if n % 2000 == 0 then task.wait() end
        if d:IsA("TextLabel") and clean(d.Text):find("JOIN RAID", 1, true) then
            local g = d:FindFirstAncestorWhichIsA("BillboardGui") or d:FindFirstAncestorWhichIsA("SurfaceGui")
            local part = g and (g.Adornee or g:FindFirstAncestorWhichIsA("BasePart"))
            if part then table.insert(list, part) end
        elseif d:IsA("BasePart") then
            local nm = d.Name:lower()
            if nm:find("raid") and nm:find("pad") then table.insert(list, d) end
        end
    end
    return list
end

local function walkToPad()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return false end
    if not padCands then padCands = collectPads() end
    local best, bestD
    for _, part in ipairs(padCands) do
        if part.Parent then
            local d = (part.Position - root.Position).Magnitude
            if not bestD or d < bestD then best, bestD = part, d end
        end
    end
    -- hanya jalan kalau pad cukup dekat (setelah teleport dari menu RAIDS)
    if best and bestD < 250 then
        hum:MoveTo(Vector3.new(best.Position.X, root.Position.Y, best.Position.Z))
        return true
    end
    return false
end

-- Deteksi layar yang ketat (hindari salah cocok dengan teks deskripsi menu)
local function onPickBall()
    if has("SWAP BALL", true) then return true end
    for _, e in ipairs(screen) do
        if e.t == "PICK YOUR BALL" or e.t:match("^PICK YOUR BALL%s*%p*%s*%d+$") then return true end
    end
    return false
end

local function inRound()
    for _, e in ipairs(screen) do
        if e.t:match("^ROUND %d+$") then return true end
    end
    return false
end

-- ---------- Alur STORY (sesuai video) ----------
local function storyStep()
    local now = tick()

    -- Setelah QUEUE muncul START NOW -> tekan
    local startNow = find("START NOW", true)[1]
    if startNow then
        S.busyUntil = now + CFG.BUSY
        S.storyDiffAt = nil
        setStatus("Menekan START NOW")
        press("startnow", startNow, 2.5)
        return
    end

    -- Menu "Choose Your Battle" -> kartu STORY (pilih yang paling besar, bukan tombol kecil di HUD)
    if has("CHOOSE YOUR BATTLE") then
        local best, bestA
        for _, o in ipairs(find("STORY", true)) do
            local a = o.AbsoluteSize.X * o.AbsoluteSize.Y
            if not bestA or a > bestA then best, bestA = o, a end
        end
        if best then
            S.busyUntil = now + CFG.BUSY
            setStatus("Memilih STORY")
            press("story", best, 3)
        end
        return
    end

    -- Peta story: pilih boss -> difficulty -> QUEUE
    if has("WAR PARTY") or has("BATTLES WON") then
        S.busyUntil = now + CFG.BUSY

        -- 1) Kartu boss (label persis di kartu paling atas; "HAWKS" di bawah hanya papan nama)
        if not has("BOSS: " .. CFG.STORY_BOSS) then
            local card
            for _, o in ipairs(find(CFG.STORY_BOSS, true)) do
                if not card or o.AbsolutePosition.Y < card.AbsolutePosition.Y then card = o end
            end
            S.storyDiffAt = nil
            if card then
                setStatus("Memilih boss " .. CFG.STORY_BOSS)
                press("sboss", card, 2)
            else
                setStatus("Mencari kartu " .. CFG.STORY_BOSS)
            end
            return
        end

        -- 2) Difficulty: terkonfirmasi lewat teks "CLEARED ..x ON NIGHTMARE"
        if not has("ON " .. CFG.STORY_DIFF) then
            local at = S.storyDiffAt
            if at == nil or now - at > 6 then
                local btn = find(CFG.STORY_DIFF, true)[1]
                if btn and press("sdiff", btn, 2) then S.storyDiffAt = now end
                setStatus("Memilih " .. CFG.STORY_DIFF)
                return
            elseif now - at < 1.5 then
                setStatus("Menunggu " .. CFG.STORY_DIFF .. " aktif")
                return
            end
        end

        -- 3) QUEUE (tombol hijau)
        local q = find("QUEUE", true)[1]
        if q then
            setStatus("Menekan QUEUE")
            press("queue", q, 3)
        else
            setStatus("Menunggu START NOW")
        end
        return
    end

    -- Tidak ada layar story -> tekan PLAY (kalau tidak sibuk)
    if now > S.busyUntil then
        local play = find("PLAY", true)[1]
        if play then
            setStatus("Menekan PLAY")
            if press("play", play, 6) then S.busyUntil = now + 8 end
            return
        end
    end
    setStatus("Menunggu...")
end

-- ---------- Logika utama (sesuai video) ----------
local function step()
    -- 0) Layar hasil. STORY: tekan REPLAY. RAID: tekan CONTINUE.
    local resultScreen = has("VICTORY") or has("DEFEAT") or has("EVERYTHING YOU EARNED") or has("YOUR DAMAGE")
    if resultScreen then
        if S.mode == "story" and has("REPLAY", true) then
            S.busyUntil = tick() + CFG.BUSY
            setStatus("Menekan REPLAY")
            press("replay", find("REPLAY", true)[1], 3)
            return
        elseif has("CONTINUE", true) then
            S.busyUntil = tick() + CFG.BUSY
            S.padUntil = 0
            setStatus("Menekan CONTINUE")
            press("continue", find("CONTINUE", true)[1], 3)
            return
        end
    end

    -- 1) Daftar bola terbuka -> klik Spiral Shemon (kalau tidak terlihat, gulir daftar)
    if has("CHOOSE YOUR BALL") then
        S.busyUntil = tick() + CFG.BUSY
        local balls = find(CFG.BALL)
        if #balls > 0 then
            local b = balls[1]
            local target = findButton(b)
            if not target then
                local free = nearestInRow(b, "FREE")
                if free and (free.AbsolutePosition - b.AbsolutePosition).Magnitude < 220 then target = free end
            end
            setStatus("Memilih " .. CFG.BALL)
            press("ball", target or b)
        else
            setStatus("Mencari " .. CFG.BALL .. "...")
            local sf
            for _, e in ipairs(screen) do
                if e.t == "FREE" then sf = e.obj:FindFirstAncestorWhichIsA("ScrollingFrame"); if sf then break end end
            end
            if sf and (not last.scroll or tick() - last.scroll > 0.8) then
                last.scroll = tick()
                local maxY = math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y)
                local y = sf.CanvasPosition.Y + sf.AbsoluteWindowSize.Y * 0.7
                sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, y > maxY and 0 or y)
            end
        end
        return
    end

    -- 2) Layar PICK YOUR BALL -> kalau Spiral Shemon belum terpasang, tekan SWAP BALL
    if onPickBall() then
        S.padUntil = 0
        S.busyUntil = tick() + CFG.BUSY
        if has(CFG.BALL) then
            setStatus(CFG.BALL .. " sudah terpasang, menunggu ronde")
        else
            local swaps = find("SWAP BALL", true)
            local t = swaps[CFG.SWAP_INDEX] or swaps[1]
            if t then
                setStatus("Menekan SWAP BALL")
                press("swap", t, 3)
            end
        end
        return
    end

    -- 3) Sedang bertarung -> tahan, jangan klik apa pun
    if has("LOCK AIM", true) or inRound() then
        S.busyUntil = tick() + CFG.BUSY
        setStatus("Sedang bertarung")
        return
    end

    -- Mode STORY punya alur sendiri
    if S.mode == "story" then
        storyStep()
        return
    end

    -- 4) Layar vote. Tiap tombol diikat ke barisnya sendiri (jarak vertikal kecil),
    --    jadi tombol baris lain tidak pernah ikut tertekan.
    local ROW = 30

    -- Cari tombol VOTE / VOTED di baris label tertentu
    local function rowState(lbl)
        local v, d = nearestInRow(lbl, "VOTE")
        local done, dd = nearestInRow(lbl, "VOTED")
        if v and d < ROW and (not done or d <= dd) then return "VOTE", v, d end
        if done and dd < ROW then return "VOTED", done, dd end
        return nil
    end

    -- Dari semua label bernama `name`, pilih yang TERBAIK = jarak vertikal ke tombolnya paling kecil.
    -- (Papan "STARTING IN" di pojok layar juga memuat tulisan NIGHTMARE/NORMAL; label itu
    --  tidak boleh dianggap baris panel, jadi yang dipakai selalu yang paling sejajar dengan tombol.)
    local function bestRow(name)
        local bl, bs, bb, bd
        for _, lbl in ipairs(find(name, true)) do
            local st, btn, d = rowState(lbl)
            if st and (not bd or d < bd) then bl, bs, bb, bd = lbl, st, btn, d end
        end
        if bs then return { st = bs, btn = bb, lbl = bl, d = bd } end
    end

    -- Pastikan tombol masih sejajar dengan labelnya TEPAT sebelum klik
    -- (baris bisa bergeser saat party berubah atau panel dibangun ulang)
    local function aligned(lbl, btn)
        if not (lbl and btn and lbl.Parent and btn.Parent) then return false end
        if not (isShown(lbl) and isShown(btn)) then return false end
        local ly = lbl.AbsolutePosition.Y + lbl.AbsoluteSize.Y / 2
        local by = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
        return math.abs(ly - by) < ROW
    end

    -- Penanda panel: difficulty punya "STARTS IN <detik>", panel boss punya judul "BOSS VOTE"
    local startsIn = false
    for _, e in ipairs(screen) do
        if e.t:match("^STARTS IN") then startsIn = true break end
    end

    -- Panel DIFFICULTY: NORMAL, HARD, dan NIGHTMARE masing-masing punya tombol di barisnya
    local rows, nRows = {}, 0
    for _, nm in ipairs({ "NORMAL", "HARD", "NIGHTMARE" }) do
        local r = bestRow(nm)
        if r then rows[nm] = r; nRows += 1 end
    end
    if startsIn and nRows >= 2 and rows[CFG.DIFFICULTY] then
        S.lastVoteUI = tick()
        S.padUntil = 0
        S.busyUntil = tick() + CFG.BUSY
        local r = rows[CFG.DIFFICULTY]
        if r.st == "VOTE" then
            if aligned(r.lbl, r.btn) then
                -- percobaan ganjil: sinyal tombol; genap: klik layar (supaya salah satunya pasti masuk)
                local mode = ((S.diffTries or 0) % 2 == 0) and "conn" or "vim"
                setStatus("Vote " .. CFG.DIFFICULTY .. " (" .. ((S.diffTries or 0) + 1) .. ")")
                if press("diff", r.btn, 1.5, mode) then S.diffTries = (S.diffTries or 0) + 1 end
            else
                setStatus("Baris bergeser, menunggu")
            end
        else
            S.diffTries = 0
            setStatus(CFG.DIFFICULTY .. " sudah di-vote, menunggu")
        end
        return
    end

    -- Panel BOSS: ada judul "BOSS VOTE" persis
    if has("BOSS VOTE", true) and not startsIn then
        S.lastVoteUI = tick()
        S.padUntil = 0
        S.busyUntil = tick() + CFG.BUSY
        local br = bestRow(CFG.BOSS)
        if br then
            if br.st == "VOTE" then
                if aligned(br.lbl, br.btn) then
                    local mode = ((S.bossTries or 0) % 2 == 0) and "conn" or "vim"
                    setStatus("Vote " .. CFG.BOSS)
                    if press("boss", br.btn, 2, mode) then S.bossTries = (S.bossTries or 0) + 1 end
                end
                return
            else
                S.bossTries = 0
                setStatus(CFG.BOSS .. " sudah di-vote")
                return
            end
        end
        setStatus("Menunggu baris " .. CFG.BOSS)
        return
    end

    -- 6) Menu "Choose Your Battle" -> klik RAIDS
    if has("CHOOSE YOUR BATTLE") or (has("RAIDS", true) and has("GO TO RAID PAD")) then
        local raids = find("RAIDS", true)[1] or find("GO TO RAID PAD")[1]
        if raids then
            S.busyUntil = tick() + CFG.BUSY
            padCands = nil
            S.padUntil = tick() + 30
            setStatus("Memilih RAIDS")
            press("raids", raids)
        end
        return
    end

    -- 7b) Baru pilih RAIDS: terus jalan ke Raid Pad sampai layar vote muncul
    if tick() < (S.padUntil or 0) then
        setStatus("Jalan ke Raid Pad")
        if not last.pad or tick() - last.pad > 2.5 then
            last.pad = tick()
            walkToPad()
        end
        return
    end

    -- 8) Tidak ada layar raid -> tekan PLAY (hanya kalau tidak sedang sibuk)
    if tick() > S.busyUntil then
        local play = find("PLAY", true)[1]
        if play then
            setStatus("Menekan PLAY")
            if press("play", play, 6) then S.busyUntil = tick() + 8 end
            return
        end
    end
    setStatus("Menunggu...")
end

task.spawn(function()
    task.wait(1.5)
    while S.alive do
        if S.mode then
            local ok, err = pcall(function()
                PlayerGui = player:FindFirstChild("PlayerGui") or PlayerGui
                local tok = S.token
                scan()
                if S.alive and S.mode and S.token == tok then step() end
            end)
            if not ok then warn("[AutoRaid] error:", err) end
        end
        local fast = tick() - (S.lastVoteUI or 0) < 20
        task.wait(fast and 0.5 or CFG.LOOP)
    end
end)

end)

if not __ok then
    warn("[AutoRaid] GAGAL: " .. tostring(__err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "AutoRaid gagal", Text = tostring(__err):sub(1, 180), Duration = 20 })
    end)
    pcall(function()
        local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local g = Instance.new("ScreenGui"); g.Name = "AutoRaidError"; g.ResetOnSpawn = false; g.Parent = pg
        local t = Instance.new("TextLabel", g)
        t.Size = UDim2.new(0.8, 0, 0, 90); t.Position = UDim2.new(0.1, 0, 0, 10)
        t.BackgroundColor3 = Color3.fromRGB(120, 20, 30); t.TextColor3 = Color3.new(1, 1, 1)
        t.TextWrapped = true; t.TextSize = 14; t.Font = Enum.Font.Gotham
        t.Text = "AutoRaid gagal:\n" .. tostring(__err)
    end)
end
