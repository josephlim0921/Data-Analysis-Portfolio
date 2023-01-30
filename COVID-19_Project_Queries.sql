/*
COVID 19 Data Exploration

Skills used: Joins, CTE's Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Notes: continent IS NULL - shows continents only
	   continent IS NOT NULL - Shows countries only

*/

SELECT * FROM dbo.CovidDeaths$
	WHERE continent IS NULL

USE PortfolioProject

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	ORDER BY 1,2


-- QUERIES REGARDING COUNTRIES


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
	FROM dbo.CovidDeaths$
	WHERE location = 'Canada' AND continent IS NOT NULL
	ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of the population infected with COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE location = 'Canada' AND continent IS NOT NULL
	ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY PercentPopulationInfected DESC


-- BREAKING THINGS DOWN BY CONTINENT


-- Showing Continents with the Highest Death Count 
SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC

-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your continient

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of the population infected with COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	ORDER BY 1,2

-- Continents with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestCovidCasePercentage 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	GROUP BY location, population
	ORDER BY HighestCovidCasePercentage DESC


-- GLOBAL NUMBERS


SELECT date, SUM(new_cases) AS NewCases, SUM(CAST(new_deaths AS INT)) AS NewDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100  AS DeathPercentage 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY date ASC


-- Looking at Total Population vs Vaccinations using a CTE

WITH POPvsVAC (continent, location, date, population, new_vaccinations, RollingVaccinationCount) AS

(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinationCount 
	FROM dbo.CovidDeaths$ AS dea
	JOIN dbo.CovidVaccinations$ AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL 
)

SELECT *, ROUND((RollingVaccinationCount/population)*100,8) 
	FROM POPvsVAC
	ORDER BY location, date


-- Looking at Total Population vs Vaccinations using a Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinationCount 
	FROM dbo.CovidDeaths$ AS dea
	JOIN dbo.CovidVaccinations$ AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, ROUND((RollingVaccinationCount/population)*100,8) 
	FROM #PercentPopulationVaccinated
	ORDER BY location, date



-- Queries that are going to be used for visualization

--1. TOTAL CASES VS TOTAL DEATHS + DEATH PERCENTAGE

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	ORDER BY 1,2

--2. TOTAL DEATH COUNT PER CONTINENT

SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC

--3. HIGHEST INFECTION COUNT FOR EACH COUNTRY, ORDERED BY PERCENT POPULATION INFECTED

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY PercentPopulationInfected DESC

--4. HIGHEST INFECTION COUNT FOR EACH COUNTRY, ORDERED BY PERCENT POPULATION INFECTED


SELECT location, date, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location, population, date
	ORDER BY PercentPopulationInfected DESC


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinationCount 
	FROM dbo.CovidDeaths$ AS dea
	JOIN dbo.CovidVaccinations$ AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT null 
	
