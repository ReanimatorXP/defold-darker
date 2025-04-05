-- app/darker/darker.lua
-- Модуль для управления эффектом "Прожектор" (Spotlight)

local M = {}

local HIGHLIGHT_PREDICATE = "highlight_go" -- Предикат для рендера в маску
local BLACK_COLOR = vmath.vector4(0, 0, 0, 0) -- Цвет для очистки RT (черный с альфа 0)

-- Сообщения для управления эффектом
M.MSG_SPOTLIGHT = hash("spotlight")
M.MSG_UPDATE_MASK = hash("update_mask")
M.MSG_REVERT_ORIGINAL_MATERIALS = hash("revert_original_materials")

-- --- Состояние модуля ---
local state = {
    is_active = false,              -- Активен ли эффект в данный момент
    needs_mask_update = false,      -- Нужно ли обновить маску в рендер-скрипте
    targets = {},                   -- { [url] = original_material_resource } - Хранит URL и оригинальный ресурс материала
    rt_mask = nil,                  -- Хэндл Render Target
    rt_params = nil,                -- Параметры для RT, заполняются в create_render_target
}

M.highlight_go_pred = nil           -- Предикат для рендеринга в маску
M.highlight_go_mat = nil            -- Материал для подсветки
M.mask_texture_sampler = 'mask_texture' -- Имя текстуры для маски (глобальная переменная для доступа из других модулей)
M.script = nil                      -- URL Darker-script для отправки сообщений
----------------------

-- --- Внутренние функции ---

-- Создает или обновляет Render Target для маски
local function create_render_target()
    -- Если RT уже существует, удаляем старый (на случай изменения размера окна в будущем)
    if state.rt_mask then
        render.delete_render_target(state.rt_mask)
        state.rt_mask = nil
    end

    -- Получаем текущие размеры окна для RT через render API
    local window_width = render.get_window_width()
    local window_height = render.get_window_height()

    -- Инициализируем параметры RT
    state.rt_params = {
        [graphics.BUFFER_TYPE_COLOR0_BIT] = {
            format = graphics.TEXTURE_FORMAT_RGBA,
            width = window_width,
            height = window_height
        }
    }

    -- Создаем новый RT, используя параметры из state.rt_params
    state.rt_mask = render.render_target("darker_mask_rt", state.rt_params)

    if state.rt_mask then
        print("Darker: Render Target created/updated (" .. window_width .. "x" .. window_height .. ")")
    else
        print("Darker Error: Failed to create Render Target")
    end
end

-- Устанавливает цели для подсветки
local function set_targets(go_ids)
    -- Очищаем предыдущие цели
    state.targets = {}

    -- Если массив go_ids не пустой, устанавливаем новые цели
    if go_ids and #go_ids > 0 then
        print("Darker [set_targets]: Setting targets from array ", go_ids)

        -- Сохраняем новые цели и их оригинальные материалы
        for _, go_id in ipairs(go_ids) do
            local url = msg.url(go_id)
            url.fragment = url.fragment or "sprite"
            if go.exists(url) then
                local material = go.get(url, "material")
                if material then
                    state.targets[url] = material
                    print("Darker [set_targets]: Stored target", url)
                else
                    print("Darker Warning [set_targets]: Could not get material for", url)
                end
            else
                print("Darker Warning [set_targets]: GameObject does not exist", url)
            end
        end
    -- Если массив пустой, очищаем цели
    else
        print("Darker [set_targets]: Clear mask from spotlights")
    end

    return true
end

-- --- API Функции ---

-- Добавляет предикат и создает Render Target
function M.init()
    print("Darker: Initializing")
    M.highlight_go_pred = render.predicate({HIGHLIGHT_PREDICATE})
    create_render_target()
end

-- Восстанавливает оригинальные материалы для всех целевых GO
function M.revert_original_materials()
    print("Darker: Revert original materials")
    for url, original_material_resource in pairs(state.targets) do
        go.set(url, "material", original_material_resource)
    end
end

-- Применяет highlight материалы к целевым GO
function M.apply_highlight_materials()
    print("Darker [apply_materials]: Applying highlight materials")

    for url, _ in pairs(state.targets) do
        if not go.exists(url) then
            print("Darker Warning [apply_materials]: GameObject does not exist", url)
            state.targets[url] = nil
        else
            go.set(url, "material", M.highlight_go_mat)
        end
    end
end

-- Применяет подсветку для сохраненных целей
function M.update_mask()
    if state.needs_mask_update then
        print("Darker [update_mask]: No need to apply spotlight")
        return false
    end

    print("Darker [update_mask]: Applying spotlight to saved targets")

    M.apply_highlight_materials()

    state.needs_mask_update = true
    state.is_active = true

    return true
end

-- Устанавливает подсветку для указанных GO
function M.spotlight(go_ids)
    if set_targets(go_ids) then
        return M.update_mask()
    end

    return false
end

-- Функция отрисовки маски
function M.draw_mask()
    -- Рисуем маску только если она была обновлена
    if state.needs_mask_update then

        -- Проверяем, существует ли RT
        if not state.rt_mask then
            print("Darker Error [draw_mask]: Mask Render Target not available for drawing.")
            return
        end

        print("Darker [draw_mask]: Drawing mask to Render Target")
        render.set_render_target(state.rt_mask)
        render.clear({[graphics.BUFFER_TYPE_COLOR0_BIT] = BLACK_COLOR})
        render.draw(M.highlight_go_pred)
        render.set_render_target(render.RENDER_TARGET_DEFAULT)

        -- Маска обновлена
        state.needs_mask_update = false
        -- Возвращаем оригинальные материалы
        msg.post(M.script, M.MSG_REVERT_ORIGINAL_MATERIALS)
    end
end

--- Возвращает хэндл Render Target для использования в рендер-скрипте
--- @return string|userdata Созданный Render Target
function M.get_mask_rt()
    return state.rt_mask
end

-- --- Обработка изменения размера окна ---
function M.on_window_resized()
    render.set_render_target_size(state.rt_mask, render.get_window_width(), render.get_window_height())

    if state.is_active then
        print("Darker: Window resized, Render Target updated")
        msg.post(M.script, M.MSG_UPDATE_MASK)
    end
end

return M