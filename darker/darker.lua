-- app/darker/darker.lua
-- Модуль для управления эффектом "Прожектор" (Spotlight)

local M = {}

-- --- Конфигурация (можно вынести во внешний файл или передавать в init) ---
local HIGHLIGHT_PREDICATE = "highlight_go" -- Предикат для рендера в маску
--------------------------------------------------------------------------

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
    restore_timer_handle = nil,     -- Хэндл таймера для восстановления материалов
    mask_rt = nil,                  -- Хэндл Render Target
    rt_params = nil,                -- Параметры для RT, заполняются в create_render_target
}

M.highlight_go_pred = nil -- Предикат для рендеринга в маску (глобальная переменная для доступа из других модулей)
M.highlight_go_mat = nil -- Материал для подсветки (глобальная переменная для доступа из других модулей)
M.mask_texture_sampler = 'mask_texture' -- Имя текстуры для маски (глобальная переменная для доступа из других модулей)
M.script = nil -- GO URL для отправки сообщений
----------------------

-- --- Внутренние функции ---

-- Создает или обновляет Render Target для маски
local function create_render_target()
    -- Если RT уже существует, удаляем старый (на случай изменения размера окна в будущем)
    if state.mask_rt then
        render.delete_render_target(state.mask_rt)
        state.mask_rt = nil
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
    state.mask_rt = render.render_target("darker_mask_rt", state.rt_params)

    if state.mask_rt then
        print("Darker: Render Target created/updated (" .. window_width .. "x" .. window_height .. ")")
    else
        print("Darker Error: Failed to create Render Target")
    end
end

-- Устанавливает цели для подсветки
local function set_targets(go_ids)
    print("Darker [set_targets]: Setting targets", go_ids)
    assert(type(go_ids) == "table", "go_ids must be a table (array or map)")
    assert(#go_ids > 0, "go_ids must not be empty")

    -- Очищаем предыдущие цели
    state.targets = {}

    -- Сохраняем новые цели и их оригинальные материалы
    for _, go_id in ipairs(go_ids) do
        local url = msg.url(nil, go_id, "sprite")
        local material = go.get(url, "material")
        if material then
            state.targets[url] = material
            print("Darker [set_targets]: Stored target", url)
        else
            print("Darker Warning [set_targets]: Could not get material for", url)
        end
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
        go.set(url, "material", M.highlight_go_mat)
    end
end

-- Применяет подсветку для сохраненных целей
function M.update_mask()
    if state.needs_mask_update then
        print("Darker [update_mask]: No need to apply spotlight")
        return false
    end

    print("Darker [update_mask]: Applying spotlight to saved targets")

    if not next(state.targets) then
        print("Darker Warning [update_mask]: No targets to highlight")
        return false
    end

    M.apply_highlight_materials()

    state.needs_mask_update = true
    state.is_active = true

    return true
end

-- Устанавливает подсветку для указанных GO
function M.spotlight(go_ids)
    print("Darker [set_mask]: Setting mask for", go_ids)

    if set_targets(go_ids) then
        return M.update_mask()
    end

    return false
end

-- Функция отрисовки маски
function M.draw_mask()
    -- Проверяем, существует ли RT и нужно ли обновление
    if not state.mask_rt then
        print("Darker Error [draw_mask]: Mask Render Target not available for drawing.")
        return
    end

    if state.needs_mask_update then
        print("Darker [draw_mask]: Drawing mask to Render Target")
        render.set_render_target(state.mask_rt)
        render.clear({[graphics.BUFFER_TYPE_COLOR0_BIT] = BLACK_COLOR})
        render.draw(M.highlight_go_pred)
        render.set_render_target(render.RENDER_TARGET_DEFAULT)
        state.needs_mask_update = false

        msg.post(M.script, M.MSG_REVERT_ORIGINAL_MATERIALS)
    end
end

--- Gets the render target for the mask
--- @return string|userdata The render target for the mask
function M.get_mask_rt()
    -- Возвращает хэндл Render Target для использования в рендер-скрипте
    return state.mask_rt
end

-- --- Обработка изменения размера окна ---
function M.on_window_resized()
    render.set_render_target_size(state.mask_rt, render.get_window_width(), render.get_window_height())

    if state.is_active then
        print("Darker: Window resized, Render Target updated")
        msg.post(M.script, M.MSG_UPDATE_MASK)
    end
end

return M