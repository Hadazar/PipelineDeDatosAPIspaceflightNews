
-- -------------------ARTICLES

-- Distribucion de articulos por mes-año y tema
SELECT 
    DATE_TRUNC('month', published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_articulos
FROM fact_article fa
JOIN dim_topic dt ON fa.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_articulos DESC;

-- Distribucion de articulos por mes y tema
SELECT 
    EXTRACT(MONTH FROM published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_articulos
FROM fact_article fa
JOIN dim_topic dt ON fa.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_articulos DESC;

-- Fuentes mas influyentes historicamente en publicacion de articulos
SELECT 
    dns.name AS fuente,
    COUNT(*) AS total_articulos
FROM fact_article fa
JOIN dim_news_source dns ON fa.source_id = dns.source_id
GROUP BY fuente
ORDER BY total_articulos DESC;

-- -------------------BLOGS

-- Distribucion de blogs por mes-año y tema
SELECT 
    DATE_TRUNC('month', published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_blogs
FROM fact_blog fb
JOIN dim_topic dt ON fb.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_blogs DESC;

-- Distribucion de blogs por mes y tema
SELECT 
    EXTRACT(MONTH FROM published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_blogs
FROM fact_blog fb
JOIN dim_topic dt ON fb.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_blogs DESC;

-- Fuentes mas influyentes historicamente en publicacion de blogs
SELECT 
    dns.name AS fuente,
    COUNT(*) AS total_blogs
FROM fact_blog fb
JOIN dim_news_source dns ON fb.source_id = dns.source_id
GROUP BY fuente
ORDER BY total_blogs DESC;


-- -------------------REPORTS

-- Distribucion de reportes por mes-año y tema
SELECT 
    DATE_TRUNC('month', published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_reportes
FROM fact_report fr
JOIN dim_topic dt ON fr.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_reportes DESC;

-- Distribucion de reportes por mes y tema
SELECT 
    EXTRACT(MONTH FROM published_at) AS mes,
    dt.name AS tema,
    COUNT(*) AS total_reportes
FROM fact_report fr
JOIN dim_topic dt ON fr.topic_id = dt.topic_id
GROUP BY mes, tema
ORDER BY mes DESC, total_reportes DESC;

-- Fuentes mas influyentes historicamente en publicacion de reportes
SELECT 
    dns.name AS fuente,
    COUNT(*) AS total_reportes
FROM fact_report fr
JOIN dim_news_source dns ON fr.source_id = dns.source_id
GROUP BY fuente
ORDER BY total_reportes DESC;


