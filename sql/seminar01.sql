-- =====================================================================
--  Семинар 1 — ваши решения
--  ФИО: ______________________   Группа: ________
--
--  Прогнать весь файл:  make run
--  Открыть консоль:     make psql
-- =====================================================================
set timezone = 'Europe/Moscow';

-- ---------------------------------------------------------------------
-- Часть 2.2. Осмотритесь — запишите ответы прямо здесь, в комментариях
-- ---------------------------------------------------------------------
-- Строк в таблицах:        
-- ...station 3  unit 7  sensor 18  telemetry 24462  event 26  maintenance 11
select 'station' as name, count(*) from station
union ALL
select 'unit', count(*) from unit
union ALL
select 'sensor', count(*) from sensor
union ALL
select 'telemetry', count(*) from telemetry
union ALL
select 'event', count(*) from event
union ALL
select 'maintenance', count(*) from maintenance;

-- Период телеметрии:       с 2026-09-01 21:00:00+00 по 2026-09-02 21:00:00+00
select min(ts), max(ts) from telemetry;
-- Значения sensor.kind:   чистые
select distinct kind
from sensor;
-- Значения event.severity: 
-- есть одни и те же слова с разными регистрами
-- пробелы в названиях
-- и просто неправильно названнык
select distinct severity as uniq, length(severity)
from event;
-- Датчики без измерений:  5-ый  
select s.id
from sensor s 
left join telemetry t 
on s.id = t.sensor_id
where t.sensor_id is null;
-- Агрегаты без датчиков:   GPA-4
select u.id
from unit u
left join sensor s
on u.id = s.unit_id
where s.unit_id is null;
-- «Грязная» запись в maintenance (id и что не так): 
--у id = 2 фамилия с маленькой и нет имени и отчества
-- у id = 3 только первая буква имени
-- у id IN (3, 6, 9, 10) пустые ячейки в столбце parts,
-- а у id = 2 прошло числом 6312 что-то написано непонятно что
select *
from maintenance;



-- ---------------------------------------------------------------------
-- Задача 1. Агрегаты и площадки
-- Ожидается: 7 строк; первыми идут P-1, P-2 (КС Восточная)
-- ---------------------------------------------------------------------
-- Задача 1
select u.id, u.model, s.name as station
from   unit u
join   station s on s.id = u.station_id
order  by s.name, u.id;


-- ---------------------------------------------------------------------
-- Задача 2. Сколько датчиков на агрегате
-- Ожидается: 7 строк; GPA-1 → 5, GPA-4 → 0
-- ---------------------------------------------------------------------
-- Задача 2
select u.id, count(s.id)
from unit u
left join sensor s
on u.id = s.unit_id
group by u.id;



-- ---------------------------------------------------------------------
-- Задача 3. Средняя температура за сутки (датчики kind = 'temp')
-- Ожидается: 4 строки; GPA-2 → 66.1
-- ---------------------------------------------------------------------
-- Задача 3
select DISTINCT unit_id as name, avg(value)
from sensor s
left join telemetry t
on s.id = t.sensor_id
where kind = 'temp'
group by name
order by name;


-- ---------------------------------------------------------------------
-- Задача 4. Датчики температуры с максимумом > 85
-- Ожидается: 1 строка — TE-302 (GPA-2), ~88.3
-- ---------------------------------------------------------------------
-- Задача 4
select *
from (select DISTINCT tag, max(value) as maximum
from sensor s
left join telemetry t
on s.id = t.sensor_id
where kind = 'temp'
group by tag)
where maximum > 85
order by tag;


-- ---------------------------------------------------------------------
-- Задача 5. Почасовой профиль температуры подшипника GPA-2
-- Ожидается: 25 строк; 11:00 → 73.4, 13:00 → 83.8, 14:00 → 85.5
-- ---------------------------------------------------------------------
-- Задача 5
select DATE_PART('hour', ts)  as hour, round(avg(value), 1)
from sensor s
left join telemetry t
on s.id = t.sensor_id
where kind = 'temp' and unit_id = 'GPA-2'
group by hour
order by hour;




-- ---------------------------------------------------------------------
-- Задача 6. События по площадкам и severity
-- Ожидается: 10 строк «как есть». Почему не 9? Посмотрите на severity внимательно.
-- ---------------------------------------------------------------------
-- Задача 6
select s.name, e.severity, count(e.id) as cnt
from unit u
join event e
on u.id = e.unit_id
join station s 
on u.station_id = s.id
group by s.name, e.severity;





-- ---------------------------------------------------------------------
-- Задача 7. Агрегаты без событий alarm / unplanned_stop
-- Ожидается: 5 агрегатов. Если у вас 6 — вы не учли регистр в severity.
-- ---------------------------------------------------------------------
-- Задача 7
select id
from 
(select distinct u.id, count(u.id) filter (where lower(e.severity) in ('alarm', 'unplanned_stop')) as cnt
from unit u 
left join event e on u.id = e.unit_id
group by u.id) t
where cnt = 0
order by id;





-- =====================================================================
--  Со звёздочкой (не влияют на балл)
-- =====================================================================

-- Задача 8*. Последнее измерение каждого датчика (17 строк)
-- Задача 8*
select sensor_id, ts, value
from (select t.sensor_id, t.ts, t.value,
    row_number() over (partition by s.id, s.kind order by t.ts desc) as num
from telemetry t
left join sensor s on t.sensor_id = s.id) t
where num = 1
order by sensor_id, ts;



-- Задача 9*. Часы, где средняя температура TE-302 выросла > 5 °C к предыдущему часу
-- Ожидается: 12:00 и 13:00
-- Задача 9*
select date_part('hour', hour)
from (select hour, mean, mean - lag(mean) over (order by hour) as diff
from (select distinct date_trunc('hour', ts) as hour, avg(t.value) as mean
from telemetry t
left join sensor s on t.sensor_id = s.id
where s.tag = 'TE-302'
group by hour) t) t2
where diff > 5





-- Задача 10*. Ремонт в течение 48 ч после каждой внеплановой остановки
-- Ожидается: P-2 → через 30.8 ч, GPA-2 → через 4.7 ч
-- Задача 10*



-- Задача 11*. Дубли в maintenance (только SELECT!)
-- Задача 11*


