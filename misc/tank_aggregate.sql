/*
    This stored procedure calculates the 
        - average daily consumption and 
        - the number of days until refill 
        for each tank in the Tanks table.

    It uses two common table expressions (CTEs) to calculate the daily consumption and level alerts for each tank based on the tank level changes.

    The CTE_TankLevelChanges calculates the 
        - current level, 
        - previous level, 
        - delivery amount, and 
        - days difference 
        for each tank.

    The CTE_DailyConsumption calculates the 
        - daily consumption and 
        - level alert (sudden decrease or increase in level, likely indicating a leak or overflow/missed delivery)
        based on the tank level changes.

    Finally, the main query selects the tank ID, tank name, current level, max capacity, average daily consumption, days until refill, and maximum level alert for each tank.
    The results are grouped by tank ID, tank name, current level, and max capacity.
*/
CREATE PROCEDURE usp_CalculateDaysUntilRefill
AS
BEGIN
    WITH CTE_TankLevelChanges AS (
        SELECT
            t.TankID,
            t.TankName,
            l.CurrentLevel,
            t.MaxCapacity,
            l.ReadingDateTime,
            LAG(l.CurrentLevel, 1) OVER (PARTITION BY t.TankID ORDER BY l.ReadingDateTime) AS PreviousLevel,
            DATEDIFF(DAY, LAG(l.ReadingDateTime, 1) OVER (PARTITION BY t.TankID ORDER BY l.ReadingDateTime), l.ReadingDateTime) AS DaysDiff,
            CASE
                WHEN l.DeliveryAmount IS NOT NULL THEN l.DeliveryAmount
                ELSE 0
            END AS DeliveryAmount
        FROM
            Tanks t
            JOIN TankLevels l ON t.TankID = l.TankID
    ),
    CTE_DailyConsumption AS (
        SELECT
            TankID,
            TankName,
            CurrentLevel,
            MaxCapacity,
            ReadingDateTime,
            CASE
                WHEN DaysDiff > 0 THEN (PreviousLevel - CurrentLevel + DeliveryAmount) / CAST(DaysDiff AS FLOAT)
                ELSE 0
            END AS DailyConsumption,
            CASE
                WHEN (CurrentLevel - PreviousLevel) / CAST(PreviousLevel AS FLOAT) < -0.3 THEN 1
                WHEN (CurrentLevel - PreviousLevel) / CAST(PreviousLevel AS FLOAT) > 0.2 THEN 2
                ELSE 0
            END AS LevelAlert
        FROM
            CTE_TankLevelChanges
    )
    SELECT
        TankID,
        TankName,
        CurrentLevel,
        MaxCapacity,
        AVG(DailyConsumption) AS AvgDailyConsumption,
        CASE
            WHEN AVG(DailyConsumption) = 0 THEN NULL
            ELSE (CurrentLevel / AVG(DailyConsumption))
        END AS DaysUntilRefill,
        MAX(LevelAlert) AS LevelAlert
    FROM
        CTE_DailyConsumption
    GROUP BY
        TankID,
        TankName,
        CurrentLevel,
        MaxCapacity;
END
