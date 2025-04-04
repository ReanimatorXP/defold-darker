# Defold Darker

Модуль для создания эффекта "прожектора" (spotlight) в Defold. Выделяет указанные объекты, затемняя остальную часть экрана.

## Установка
1. Добавьте зависимость в `game.project`.
2. Добавьте `/darker/darker.go` в основную коллекцию:
3. Добавьте материал `/darker/materials/darker.material` в GUI и установите на вашу ноду, которая будет затемнять.
4. Нода не использует текстуру, просто установите нужный цвет в редакторе (используя нужную прозрачность).

## Настройка Render Script
**Вариант 1:** Используйте готовый `/darker/render/darker.render_script`.

**Вариант 2:** Измените свой скрипт:
```lua
-- В начале файла
local darker = require "darker.darker"

function init(self)
    -- ...existing code...
    darker.init()
end

function update(self)
    -- ...existing code...
    darker.draw_mask()
    -- ...далее отрисовка объектов...
    
    -- Перед отрисовкой GUI
    render.enable_texture(darker.mask_texture_sampler, darker.get_mask_rt())
    render.draw(predicates.gui, camera_gui.options)
    render.disable_texture(darker.mask_texture_sampler)
end

function on_message(self, message_id, message)
    -- ...existing code...
    if message_id == hash("window_resized") then
        darker.on_window_resized()
    end
end
```

## Использование

### Активация эффекта
```lua
-- Прямой вызов функции
darker.spotlight({ go.get_id("object1"), go.get_id("object2") })

-- ИЛИ через сообщение
msg.post("darker", hash("spotlight"), { go.get_id("object1"), go.get_id("object2") })
```

### Управление видимостью
**Важно:** Эффект рендерится в текстуру только один раз после вызова `spotlight()`. Для управления видимостью используйте GUI-ноду:

```lua
local node = gui.get_node("darker")
gui.set_enabled(node, true/false)  -- включить/выключить
gui.set_alpha(node, 0.5)           -- изменить прозрачность
```

## Поддержка TypeScript
Модуль включает файл типизации `darker.d.ts`.

## Лицензия
MIT License.