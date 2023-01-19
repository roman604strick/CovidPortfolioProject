SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- Will remove all null numbers from dataset
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..[Covid vaccinations]
--ORDER BY 3,4

-- Select data that we are going to be using

SELECT Location, date, total_cases,new_cases, total_deaths, population
FROM PortfolioProject.. CovidDeaths
ORDER BY 1,2

--Looking at Total cases vs Totat deaths
--shows likely hood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.. CovidDeaths
WHERE Location LIKE '%states%'-- will bring back results for Locations with "states" in description
AND continent IS NOT NULL
ORDER BY 1,2

--Looking at total cases vs population
--shows what percentage of population got covid
SELECT Location, date, population,total_cases, (total_cases/population)*100 AS PercentPopulationInfection
FROM PortfolioProject.. CovidDeaths
WHERE Location LIKE '%states%'-- will bring back results for Locations with "states" in description
AND continent IS NOT NULL
ORDER BY 1,2

--looking at countries with highes infection rate compared to population
SELECT Location,population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%' -- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
GROUP BY Location,population
ORDER BY PercentPopulationInfected DESC 

--Showing countries with Highest Death Count Per population
SELECT Location,MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount --CAST allows me to change Total_Deaths to an integer
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%' -- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Breaking it down by location (right way)
SELECT location,MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount --CAST allows me to change Total_Deaths to an integer
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%' -- will bring back results for Locations with "states" in description
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Breaking it down by Continent (easier for tableau purposes)
SELECT continent,MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount --CAST allows me to change Total_Deaths to an integer
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%' -- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Showing continents with highest death count
SELECT continent,MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount --CAST allows me to change Total_Deaths to an integer
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%' -- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100
AS DeathPercentage
FROM PortfolioProject.. CovidDeaths
--WHERE Location LIKE '%states%'-- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2
--will show total cases


--Global numbers by date
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100
AS DeathPercentage
FROM PortfolioProject.. CovidDeaths
--WHERE Location LIKE '%states%'-- will bring back results for Locations with "states" in description
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
--will show total cases


--looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as float)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)--everytime it gets to a new loaction it will start over. Partition will run only through canada
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Use CTE
WITH PopVsVac (Continent, location, date, population, New_Vaccination, RollinPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as float)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)--everytime it gets to a new loaction it will start over. Partition will run only through canada
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (RollinPeopleVaccinated/population) * 100
FROM PopVsVac


-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Create view to store data for later vizualization
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 