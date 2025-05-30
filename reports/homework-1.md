# Адаптация ClickHouse
## Приведите 2-3 примера использования ClickHouse в компаниях на рынке
### Яндекс
Специфика проекта: Анализ больших объемов данных, обработка логов, мониторинг производительности сервисов Яндекс.

Особенности внедрения: Использование ClickHouse в качестве хранилища данных для аналитической обработки большого объема лог-файлов различных сервисов Яндекса. Данные поступают практически в режиме реального времени от десятков тысяч серверов. Архитектуру выстроили таким образом, чтобы обеспечивать горизонтальное масштабирование путем репликации и шардирования таблиц. Таким образом обеспечивается высокая доступность и производительность системы даже при росте нагрузки.

Особенности построения архитектуры: Распределенная архитектура с использованием реплик и шардов позволяет обрабатывать запросы параллельно, обеспечивая быстрый доступ к данным и возможность оперативного анализа огромного количества логов. Развертывание кластеров ClickHouse осуществлено с применением Kubernetes для упрощения управления инфраструктурой.

### Wildberries
Специфика проекта: Система аналитики поведения пользователей на платформе электронной коммерции Wildberries.

Особенности внедрения: Интеграция ClickHouse для хранения и анализа информации о действиях пользователей на сайте и мобильных приложениях — просмотры товаров, добавления в корзину, покупки и возвраты. Благодаря высокой скорости запросов и возможности работы с большими объемами данных, компания получает оперативные инсайты о поведении покупателей, позволяющие оптимизировать маркетинговые кампании и улучшать продуктивность бизнеса.

Особенности построения архитектуры: Широкая таблица с детальной информацией о событиях интегрирована с системами сбора данных (логгерами), откуда данные собираются в ClickHouse. Используется параллельная обработка данных и специальный механизм агрегирования (материализованные представления), позволяющий получать актуальные отчеты почти мгновенно. Архитектура построена с расчетом на дальнейший рост числа клиентов и увеличение объема собираемых данных.

### АО ГНИВЦ
Специфика проекта: аналитика над чеками с касс республики Кыргызстан.

Особенности внедрения: проект системы достался компании в наследство от предыдущего разработчика (участвовавшего в создании аналогичной системы для РФ). Качество на момент передачи системы оставляло желать лучшего: не было полноценного использования кластера (3 реплики), много неоптимальных излишне нормализованных таблиц и построенных поверх них вью с джойнами.

Особенности построения архитектуры: чеки после обработки приёмным комплексом сохраняются в Apache HBase для быстрого доступа по ключу и в ClickHouse для формирования отчётов через запросы как к агрегированным таблицам, так и непосредственно с агрегациями.

## Дополнительное задание
### 1. К каким классам систем относится ClickHouse?
ClickHouse это колоночная СУБД -- хранит данные столбцами, а не строками, что обеспечивает высокую скорость выборки данных по отдельным колонкам.
Как следствие из выше, ClickHouse это аналитическая (OLAP) система -- предназначена для аналитической обработки больших объёмов данных, быстрых вычислений агрегаций и сложных аналитических операций.
Также ClickHouse это масштабируемая распределённая БД -- поддерживает репликацию и шардирование, позволяя легко расширять систему путём увеличения узлов в кластере, сохраняя высокую производительность и отказоустойчивость.

### 2. Какую проблему вы бы решили используя ClickHouse, а какую бы не стали?
Стал бы:
- агрегация и анализ логов или событий
- онлайн аналитика над большими наборами данных
- аналитика над потоковыми данными

Не стал бы:
- обработка транзакций с минимальной задержкой и гарантированной консистентностью
- обработка малых объёмов данных

### 3. Где можно получить помощь по ClickHouse и куда сообщать о багах?
1. Официальная документация https://clickhouse.com/docs
2. Официальный репозиторий в Github https://github.com/ClickHouse/ClickHouse
3. Посмотреть на StackOverflow по тэгу clickhouse https://stackoverflow.com/questions/tagged/clickhouse
4. Публичные чаты и форумы, например каналы в Telegram или сервер в Discord
