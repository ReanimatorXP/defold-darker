# Defold Darker

Модуль для создания эффекта "прожектора" (spotlight) в Defold. Выделяет указанные объекты, затемняя остальную часть экрана.

## Установка
1. Добавьте зависимость в `game.project`:
https://github.com/ReanimatorXP/defold-darker/archive/refs/heads/master.zip

2. Добавьте `/darker/darker.go` в основную коллекцию:
3. Добавьте материал `/darker/materials/darker.material` в GUI и установите на вашу ноду, которая будет затемнять.
4. Нода не использует текстуру, просто установите нужный цвет в редакторе (используя нужную прозрачность).

## Настройка Render Script
**Вариант 1:** Используйте готовый `/darker/render/darker.render_script` *(используется в нашем проекте)*

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
Можно передавать объекты как `id`, `строки с именем`, `url` или `хэши` — модуль сам определит тип.  
Если у объекта компонент спрайта называется по умолчанию `"sprite"`, его имя указывать не нужно.  
Если у компонента другое имя, его следует указать через `#`, например: `"object#custom_sprite"` или составить готовый url.

### Активация эффекта
```lua
-- Заготовленный url с кастомным именем компонента image
local object5 = msg.url(nil, "object5", "image")

-- Прямой вызов функции
darker.spotlight({ go.get_id("object1"), -- хэш
                    "object2", -- строка с именем go
                    msg.url("object3"), -- url со стандартным именем компонента sprite
                    msg.url("object4#image"), -- url с кастомным именем компонента sprite
                    object5 -- заготовленный url
                })

-- ИЛИ через сообщение "spotlight"
msg.post("darker", "spotlight", { go.get_id("object1"), "object2", msg.url("object3"), msg.url("object4#image"), object5 })
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
