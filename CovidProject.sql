--looking at total cases vs total deaths (in their country) and total%people who die on infections

SELECT location,date,total_cases,total_deaths,population,round((total_deaths/total_cases)*100,2) AS Deathpercentage
FROM CovidDeaths
ORDER BY 1,2;


--looking at USA, total cases vs total population
--%poplulation to get Covid
SELECT location,date,total_cases,total_deaths,population,round((total_cases/population)*100,2) AS infections
FROM CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1;

--looking country with highest infection rate vs population
--3.**
SELECT location,max(total_cases) AS HighestInfectionCount,max(total_cases/population)*100 AS populationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY populationInfected DESC;

--4.**
SELECT location,population,date,max(total_cases) AS HighestInfectionCount,max(total_cases/population)*100 AS populationInfected
FROM CovidDeaths
GROUP BY location, population,date
ORDER BY populationInfected DESC;

--looking at how many people die most in which country 

SELECT location,max(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania') 
GROUP BY location
ORDER BY TotalDeathCount DESC;

--break things down continents

SELECT continent,max(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania')
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--breaking down global number by date, comparing new case and deaths case per day.

SELECT sum(new_cases) as TotalCase, SUM(new_deaths) AS TotalDeaths,round(sum(new_deaths)/sum(new_cases)*100,2) AS DeathVsNewcase
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania')
GROUP BY DATE;

--1.**
SELECT sum(new_cases) as TotalCase, SUM(new_deaths) AS TotalDeaths,round(sum(new_deaths)/sum(new_cases)*100,2) AS DeathVsNewcase
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania');



--2.** --total deaths counts

SELECT continent, sum(new_deaths) AS totalDeathCount
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania') 
                AND not location IN ('World','European Union','International')
GROUP BY continent
ORDER BY totalDeathCount DESC;

--new case rolling by location and date.(window function)

SELECT location, date, new_cases, new_deaths,
        sum(new_cases) OVER (PARTITION BY location ORDER BY location,date) AS RollingCase,
        sum(new_deaths) OVER (PARTITION BY location ORDER BY location,date) AS RollingDeaths
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania') AND location like '%States%'
ORDER BY 1,2 ASC

--plus CTE
WITH PoPvsCaseDeath (location,date,new_cases,RollingDeath,RollingCase)
AS
(
SELECT location, date, new_cases, total_deaths AS RollingDeath,
        sum(new_cases) OVER (PARTITION BY location ORDER BY location,date) AS RollingCase
        
FROM CovidDeaths
WHERE continent IN ('North America','South America','Asia','Europe','Africa','Oceania')
)
SELECT *, ROUND((RollingDeath/RollingCase)*100,2) AS DeathVsNewCase
FROM PoPvsCaseDeath
WHERE location LIKE '%States%'



-- join location and date
--looking total population vs total vacinate

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
FROM CovidVaccinations vac JOIN CovidDeaths dea
ON vac.location=dea.location AND vac.date=dea.date
WHERE dea.continent IN ('North America','South America','Asia','Europe','Africa','Oceania') --AND dea.location = 'Canada'
ORDER BY 2;

--accumulate new vaccinated (window function)
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
        sum(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVacc
FROM CovidVaccinations vac JOIN CovidDeaths dea
ON vac.location=dea.location AND vac.date=dea.date
WHERE dea.continent IN ('North America','South America','Asia','Europe','Africa','Oceania')AND dea.location = 'Canada'
ORDER BY 2;


--CTE, to compare vaccinated to total population of country (Albania example)
--5.**
WITH PopVsVac (continent,location,DATE,Population,new_vaccinations,RollingVacc) 
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
        sum(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVacc
FROM CovidVaccinations vac JOIN CovidDeaths dea
ON vac.location=dea.location AND vac.date=dea.date
WHERE dea.continent IN ('North America','South America','Asia','Europe','Africa','Oceania')
)
SELECT *,Round((RollingVacc/Population)*100,2) AS VacPercentage
FROM PopVsVac
--WHERE location = 'Albania'


--Create view for data visuallization

create VIEW PopPerVacc AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
        sum(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVacc
FROM CovidVaccinations vac JOIN CovidDeaths dea
ON vac.location=dea.location AND vac.date=dea.date
WHERE dea.continent IN ('North America','South America','Asia','Europe','Africa','Oceania')

SELECT *
FROM poppervacc