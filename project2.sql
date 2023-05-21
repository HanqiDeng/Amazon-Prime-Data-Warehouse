-- create original tables credits and titles
create table credits (
	person_id numeric,
	id varchar(200),
	name varchar(200),
	character varchar(200),
	role varchar(200)
);

create table titles (
	id varchar(200),
	title varchar(200),
	type varchar(200),
	release_year numeric,
	age_certification varchar(200),
	runtime numeric,
	genres varchar(200),
	production_countries varchar(200),
	seasons numeric,
	imdb_id varchar(200),
	imdb_score numeric,
	imdb_votes numeric,
	tmdb_popularity numeric,
	tmdb_score numeric
);

-- create table fact_specifics
create table fact_specifics as select * from titles;
alter table fact_specifics 
rename column id to title_id;
alter table fact_specifics
rename column title to title_name;

-- create table dim_year
create table dim_year as select title_id, release_year from fact_specifics;

-- create table dim_age
create table dim_age (
  age_certification_id serial primary key,
  age_certification varchar(200),
  age_count integer
);

insert into dim_age (age_certification, age_count)
select age_certification, count(*)
from fact_specifics
where age_certification != 'NaN'
group by age_certification
order by count(*) desc;

-- create table dim_imdb
create table dim_imdb (
  imdb_score_id serial primary key,
  imdb_score numeric,
  imdb_count integer
);

insert into dim_imdb (imdb_score, imdb_count)
select imdb_score, count(*)
from fact_specifics
where imdb_score != 'NaN'
group by imdb_score
order by imdb_score asc;

alter table dim_imdb
add constraint dim_imdb_title_score_unique unique (imdb_score);

-- maintenance in loading delta for SCD 1 
insert into dim_imdb (imdb_score_id, imdb_score, imdb_count)
values ('4','1.5','7')
on conflict (imdb_score)
do update set imdb_count = EXCLUDED.imdb_count;

alter table credits 
rename column id to c_id;

create table joined as
select * from fact_specifics join credits on fact_specifics.title_id = credits.c_id;

-- create table fact_casts
create table fact_casts as
select j1.c_id as title_id, j1.name as director_name, count(distinct j2.name) as num_actors
from joined j1
join joined j2 on j1.c_id = j2.c_id and j1.role = 'DIRECTOR' and j2.role = 'ACTOR'
where j1.age_certification is not NULL
group by j1.c_id, j1.name;

-- create table dim_seasons with SCD 3
create table dim_seasons as select title_id, title_name, seasons from fact_specifics
where seasons != 'NaN'
group by title_id, title_name, seasons
order by seasons desc;

alter table dim_seasons
add column prior_seasons numeric,
add constraint dim_seasons_title_id_unique unique (title_id);

-- maintenance in loading delta for SCD 3
insert into dim_seasons (title_id, title_name, seasons)
values ('ts20945', 'The Three Stooges', '27.0')
on conflict (title_id)
do update set
    prior_seasons = dim_seasons.seasons,
    seasons = EXCLUDED.seasons;
	
-- create dim_title table with SCD 2
create table dim_title as select title_id, title_name from fact_specifics;
alter table dim_title
add column start_date date default current_date,
add column end_date date default '9999-12-31',
add column is_current numeric default 1;

-- answer to Question 3 
select * from dim_age;

-- answer to Question 5
create table country_genre as 
select production_countries, genre, count(*) as count
from (
  select 
    production_countries, 
    trim(lower(unnest(regexp_split_to_array(genres, E'\\[|,|\\]')))) as genre
  from fact_specifics
) as t
group by production_countries, genre
order by production_countries, count desc;
select * from country_genre;


 