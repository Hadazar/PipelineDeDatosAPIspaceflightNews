CREATE TABLE dim_news_source ( 
	source_id INTEGER IDENTITY(1,1) PRIMARY KEY,
	name VARCHAR(255)
); 

CREATE TABLE dim_topic ( 
    topic_id INTEGER IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(255)
); 

INSERT INTO dim_topic (name) VALUES
    ('Space Launches and Missions'),
    ('Satellites and Telecommunications'),
    ('Aerospace Development and Technology'),
    ('Astronomy and Space Science'),
    ('Space Industry and Economy'),
    ('Space Phenomena and Controversies'),
    ('Space Policies and Regulations'),
	('Others');

CREATE TABLE fact_article ( 
	article_id INT PRIMARY KEY,
	source_id INT references dim_news_source(source_id),
	topic_id INT references dim_topic(topic_id),
	published_at TIMESTAMP,
	title CHAR(1024),
	url VARCHAR(255),
	updated_at TIMESTAMP,
	key_words CHAR(1024),
	entities CHAR(1024)
);

CREATE TABLE fact_report ( 
	report_id INT PRIMARY KEY,
	source_id INT references dim_news_source(source_id),
	topic_id INT references dim_topic(topic_id),
	published_at TIMESTAMP,
	title CHAR(1024),
	url VARCHAR(255),
	updated_at TIMESTAMP,
	key_words CHAR(1024),
	entities CHAR(1024)
);

CREATE TABLE fact_blog ( 
	blog_id INT PRIMARY KEY,
	source_id INT references dim_news_source(source_id),
	topic_id INT references dim_topic(topic_id),
	published_at TIMESTAMP,
	title CHAR(1024),
	url VARCHAR(255),
	updated_at TIMESTAMP,
	key_words CHAR(1024),
	entities CHAR(1024)
);