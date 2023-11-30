SELECT "CovidDeaths"."location", "CovidDeaths"."date", "CovidDeaths"."total_cases", "CovidDeaths"."new_cases", "CovidDeaths"."total_deaths",
"CovidDeaths"."population_density"
FROM "public"."CovidDeaths"
ORDER BY 1, 2


--Exploring death percentage per total cases

SELECT "CovidDeaths"."location", "CovidDeaths"."date", "CovidDeaths"."total_cases", "CovidDeaths"."total_deaths", 
("CovidDeaths"."total_deaths"/"CovidDeaths"."total_cases")*100 AS Death_Percentage
FROM "public"."CovidDeaths"
INNER JOIN "public"."CovidVaxes" ON "CovidVaxes"."date" = "CovidDeaths"."date"
WHERE "CovidDeaths"."location" LIKE '%States%'
ORDER BY 1,2


--looking at countries with highest infection rate compared to population

SELECT "CovidDeaths"."location", "CovidDeaths"."population", max("CovidDeaths"."total_cases") AS "Highest_Infection_Count",
max(("CovidDeaths"."total_cases"/"CovidDeaths"."population"))*100 AS "Percent Population Infected"
FROM "public"."CovidDeaths"
GROUP BY "CovidDeaths"."location", "CovidDeaths"."population"
ORDER BY "CovidDeaths"."location" ASC



--Showing Countries with the highest death count per population
SELECT "CovidDeaths"."location", max("CovidDeaths"."total_deaths") AS "Total Death Count"
FROM "public"."CovidDeaths"
WHERE "CovidDeaths"."continent" IS NOT NULL -- since some data entries relate to the aggregate of the entire continent 
GROUP BY "CovidDeaths"."location"
ORDER BY "Total Death Count" DESC



--Showing continents with highest death counts

SELECT "CovidDeaths"."date", sum("CovidDeaths"."new_cases") AS "Total Cases", sum("CovidDeaths"."new_deaths") AS "Total Deaths",
 (sum("CovidDeaths"."total_deaths")/sum("CovidDeaths"."total_cases"))*100 AS "Death Percentage"
FROM "public"."CovidDeaths"
WHERE "CovidDeaths"."new_cases" != 0 AND "CovidDeaths"."continent" IS NOT NULL -- eliminate days where 0 new cases were documented.
-- also, continent data is input sometimes as a location without continent so to aggregate properly we find continents.
GROUP BY "CovidDeaths"."date"
ORDER BY "CovidDeaths"."date" ASC



--looking at total population vaccinated using CTE

WITH PopvsVac (continent, "location", date, population, new_vaccinations, RollingPeopleVaccinated) --creating CTE to use new Column created
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) OVER (PARTITION BY "dea"."location" ORDER BY "dea"."location", dea.date) AS "RollingPeopleVaccinated"
FROM "public"."CovidDeaths" AS dea 
JOIN "public"."CovidVaxes" AS vac 
    ON "vac"."date" = "dea"."date"
    AND "vac"."location" = "dea"."location"
WHERE dea.continent IS NOT NULL AND vac.total_boosters IS NULL --Taking into account only 1st round of vaccinations
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS "Percent Vaccinated"
FROM PopvsVac



--PopvsVac Data Validation Query to make sure percentages are correct
SELECT "CovidDeaths"."location", "CovidDeaths"."population", "CovidVaxes"."total_vaccinations", 
("CovidVaxes"."total_vaccinations"/"CovidDeaths"."population")*100 AS "Percent Vaxed"
FROM "public"."CovidDeaths"
JOIN "public"."CovidVaxes" ON "CovidVaxes"."date" = "CovidDeaths"."date" AND "CovidVaxes"."location" = "CovidDeaths"."location"
GROUP BY "CovidDeaths"."location", "CovidDeaths"."population", "CovidVaxes"."total_vaccinations"




--creating view to store data for later visualizations 

CREATE VIEW "PercentPopulationVaccinated" AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) OVER (PARTITION BY "dea"."location" ORDER BY "dea"."location", dea.date) AS "RollingPeopleVaccinated"
FROM "public"."CovidDeaths" AS dea 
JOIN "public"."CovidVaxes" AS vac 
    ON "vac"."date" = "dea"."date"
    AND "vac"."location" = "dea"."location"
WHERE dea.continent IS NOT NULL AND vac.total_boosters IS NULL 


