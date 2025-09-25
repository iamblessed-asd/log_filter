# Log filter (Perl + MySQL)

## Запуск проекта

Проект запускается в контейнере Docker. Поэтому Docker должен быть установлен и запущен.

### 1. Склонировать репозиторий
```bash
git clone https://github.com/iamblessed-asd/log_filter.git
```

### 2. Перейти в корень проекта
```bash
cd log_filter
```

### 3. Собрать контейнеры
```bash
docker-compose up --build
```
### Важно!
Сборка может собираться довольно долго (~900 секунд).

### Также если сборка происходит на windows, то docker desktop может потребовать предоставить доступ к файлам - нужно отметить "Да".
<img width="640" height="187" alt="image" src="https://github.com/user-attachments/assets/9a2f3358-d4aa-4849-bf76-0de71c6ba1f9" />

### После этого перезапустить docker desktop, в настройках во вкалдке Resources -> File sharing должны появиться пути до запрашиваемых файлов:
<img width="1288" height="723" alt="image" src="https://github.com/user-attachments/assets/79035e1c-32cb-465c-bacb-7ec98f2c8c06" />


### А затем пересобрать проект:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### После успешного запуска сервиса будут выведены сообщения
```bash
app       | MySQL запущен!
app       | Инициализация таблиц...
app       | Выполнение записи в БД из файла /usr/src/app/logs/out
app       | Время выполнения записи в БД: 3.189 секунд
app       | Загружено: 1921 в message, 8079 в log
```

### После этого веб интерфейс будет доступен по адресу
```
http://localhost:8080/
```

### Веб страница выглядит следующим образом:
<img width="860" height="247" alt="image" src="https://github.com/user-attachments/assets/f987b325-38a5-4ba6-b5c6-fe752c93b472" />

Если количество записей превышает лимит, то выводится сообщение об этом:
<img width="1285" height="614" alt="image" src="https://github.com/user-attachments/assets/e5f7bab4-808e-483b-8f00-e25f1b91ed0c" />

