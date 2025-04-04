# Defold Darker

Модуль "Spotlight" эффекта для Defold, который позволяет выделять игровые объекты затемнением всего остального на экране.

## Описание

Darker - это простой, но мощный модуль для создания эффекта "прожектора" (spotlight) в ваших играх на Defold. Он позволяет визуально выделить нужные игровые объекты, создавая оверлей, который затемняет всё кроме выбранных элементов.

## Установка

1. Добавьте этот проект как зависимость в вашем файле `game.project`
   ```
   https://github.com/your-username/defold-darker/archive/master.zip
   ```

2. **Добавьте компонент `/darker/darker.go` в вашу основную коллекцию.**
   Это обязательный шаг, так как данный игровой объект содержит скрипт, управляющий эффектом:
   
   ```
   # В вашей main.collection добавьте
   instances {
     id: "darker"
     prototype: "/darker/darker.go"
   }
   ```

3. **Создайте GUI-оверлей** для затемнения:
   - Создайте или откройте существующий GUI файл
   - Добавьте box весь экран
   - **Важно:** Выберите материал `darker.material` для этой ноды

4. **Настройте render script:**
   
   У вас есть два варианта:
   
   **Вариант 1:** Использовать готовый render script из модуля
   - Используйте `/darker/render/darker.render_script` или `/example/render/example.render_script`
   - Укажите путь к render script в вашем `.render` файле
   
   **Вариант 2:** Изменить свой существующий render script
   
   Необходимые изменения:
   
   a) Подключить модуль в начале файла:
   ```lua
   local darker = require "darker.darker"
   ```
   
   b) Инициализировать darker в функции init():
   ```lua
   function init(self)
       -- ...существующий код...
       darker.init() -- Инициализация darker
   end
   ```
   
   c) Добавить отрисовку darker маски в функции update() перед отрисовкой основных спрайтов:
   ```lua
   function update(self)
       -- ...существующий код...
       
       -- Отрисовка darker маски
       darker.draw_mask()
       
       -- ...далее отрисовка основных объектов...
   end
   ```
   
   d) Добавить текстуру darker маски перед отрисовкой GUI:
   ```lua
   -- Подготовка к отрисовке GUI
   -- ...существующий код...
   
   render.enable_state(render.STATE_STENCIL_TEST)
   
   -- Добавляем текстуру маски в шейдер GUI
   render.enable_texture(darker.mask_texture_sampler, darker.get_mask_rt())
   
   -- Отрисовка GUI как обычно
   render.draw(predicates.gui, camera_gui.options)
   
   -- Отключаем текстуру маски
   render.disable_texture(darker.mask_texture_sampler)
   ```
   
   e) Обработать изменение размера окна в функции on_message():
   ```lua
   function on_message(self, message_id, message)
       -- ...существующий код...
       
       if message_id == hash("window_resized") then
           -- ...существующий код...
           
           -- Обновляем darker при изменении размера окна
           darker.on_window_resized()
       end
   end
   ```

## Использование

### Управление затемнением

Рендеринг маски в текстуру происходит только один раз после вызова `darker.spotlight()`. После этого текстура больше не обновляется до следующего вызова функции (или изменению окна). Поэтому для управления видимостью эффекта необходимо управлять GUI нодой, а не вызывать снова функцию spotlight.

**Важно:** Управление gui-нодой с материалом `darker.material` происходит, как и с обычной gui-нодой: включаем, выклчаем, показываем, скрываем и т.д.

### Базовое использование

Вызов `darker.spotlight(...)` надо делать из go .script 
```lua
-- Получите ID объектов, которые хотите выделить
local go_ids = { go.get_id("my_object1"), go.get_id("my_object2") }

-- Включите эффект "прожектора" для этих объектов
darker.spotlight(go_ids)
```

 Альтернатива - отправить сообщение к `darker.script`:
 ```lua
```lua
 -- Получите ID объектов, которые хотите выделить
 local go_ids = { go.get_id("my_object1"), go.get_id("my_object2") }

 -- Отправьте сообщение к darker.script с ID целевых объектов
 msg.post(darker.script, { targets = go_ids })
 ```

## Полная схема интеграции

1. Добавить `/darker/darker.go` в основную коллекцию
2. Создать GUI с нодой, использующей материал `/darker/materials/darker.material`
3. Настроить render script (использовать готовый или изменить свой)
4. Вызывать `darker.spotlight()` для выделения объектов

## Лицензия

MIT License - свободно используйте в коммерческих и некоммерческих проектах.

---