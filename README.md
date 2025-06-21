# Панель управления mitmproxy

## 📦 Содержимое

- `index.html` — панель управления для GitHub Pages
- `config.json` — конфигурация подмены
- `replacement.html` — HTML-контент, который будет вставляться
- `live_script.py` — скрипт для запуска с mitmproxy

## 🚀 Как использовать

1. Создай репозиторий на GitHub, например `mitm-control`
2. Включи GitHub Pages (ветка `main`, корень)
3. Заливай туда все файлы из архива
4. Замени `yourusername` на своё имя в:
   - `config.json`
   - `live_script.py`
5. Запусти mitmproxy:
   ```
   mitmproxy -s live_script.py
   ```
6. Перейди на `index.html` из GitHub Pages
7. Управляй подменой — домены, IP, HTML, включение/отключение
