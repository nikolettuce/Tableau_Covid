SELECT *
FROM tableau_covid..covid_deaths
WHERE continent is not null
order by 3,4

--SELECT *
--FROM tableau_covid..covid_vaccinations
--order by 3,4

-- select data that we're going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM tableau_covid..covid_deaths
order by 1,2

-- total cases vs total deaths
-- how likley are you to die if you contract covid19?
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM tableau_covid..covid_deaths
WHERE location LIKE '%states'
order by 1,2

-- total cases vs population
-- what % of pop have covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as infection_rate
FROM tableau_covid..covid_deaths
--WHERE location LIKE '%states'
order by 1,2

-- which countries have highest infection rate, relative to population
SELECT location, population, MAX(total_cases) as max_infection_count, MAX((total_cases/population)) * 100 as max_infection_rate
FROM tableau_covid..covid_deaths
GROUP BY location, population
order by max_infection_rate desc

-- show countries with highest death count
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM tableau_covid..covid_deaths
where continent is not null
GROUP BY location
order by total_death_count desc

-- show continents with highest death count
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM tableau_covid..covid_deaths
where continent is null
GROUP BY location
order by total_death_count desc

-- global numbers per day
select date,
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM tableau_covid..covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- total cases/deaths
select --date,
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM tableau_covid..covid_deaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- COVID VACCINATION TABLE
SELECT *
FROM tableau_covid..covid_deaths dea
JOIN tableau_covid..covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) as new_vacs
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vacs
FROM tableau_covid..covid_deaths dea
JOIN tableau_covid..covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE 
WITH pop_vs_vac (continent, location, date, population, new_vacs, RollingPeopleVaccinated)
AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(int, vac.new_vaccinations) as new_vacs
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vacs
	FROM tableau_covid..covid_deaths dea
	JOIN tableau_covid..covid_vaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population) * 100 AS percent_vac
FROM pop_vs_vac
WHERE (RollingPeopleVaccinated/population) * 100 > 100
order by 2,3

Create View percent_pop_vacd AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM tableau_covid..covid_deaths dea
JOIN tableau_covid..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
