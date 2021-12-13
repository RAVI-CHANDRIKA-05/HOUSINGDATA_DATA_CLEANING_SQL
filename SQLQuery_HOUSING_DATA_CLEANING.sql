/*
CLEANING DATA IN SQL
*/

--GET DETAILS OF THE DATASET
EXEC sp_help 'NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA';

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'HOUSING_DATA'

--------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--------------------------------------------------------------------------------------------------------------------------------------
--STANDARDIZE DATA FORMAT(REMOVE THE TIME AND KEEP ONLY DATE)
--SEE THE SaleDate COLUMN
SELECT SaleDate 
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--ADD NEW COLUMN DateSold TO THE TABLE 
ALTER TABLE HOUSING_DATA
ADD DateSold DATE;

--UPDATE THE ADDED COLUMN WITH CONVERTED DATE FORMAT
UPDATE HOUSING_DATA
SET DateSold = CONVERT(DATE, SaleDate)

--VIEW THE NEW DATE
SELECT SaleDate, DateSold
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--LATER WE CAN DROP THE SaleDate COLUMN

--------------------------------------------------------------------------------------------------------------------------------------
--GET AGE OF PROPERTY
SELECT YEAR(GETDATE()) --GIVES CURRENT YEAR

--ADD NEW COLUMN AgeOfProperty TO THE TABLE 
ALTER TABLE NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
ADD AgeOfProperty INT;

--UPDATE THE ADDED COLUMN WITH AgeOfProperty = CURRENT YEAR-YEAR BUILT
UPDATE  NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
SET AgeOfProperty = YEAR(GETDATE())-YearBuilt

--VIEW THE AgeOfProperty
SELECT YearBuilt, AgeOfProperty
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--------------------------------------------------------------------------------------------------------------------------------------
--WORK ON PropertyAddress Column

SELECT *
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
--LOOKS LIKE ParcelID ALSO GIVES THE DETAILS ABOUT PropertyAddress

SELECT COUNT(*)
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
WHERE PropertyAddress IS NULL
--THERE ARE 29 ROWS WHERE PropErtyAddress IS NULL

--NOW SELFJOIN THE TABLE AND THEN REPLACE THE NULL IN PropertyAddress
SELECT tableone.ParcelID, tableone.PropertyAddress, tabletwo.ParcelID, tabletwo.PropertyAddress,
ISNULL(tableone.PropertyAddress,tabletwo.PropertyAddress)
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA tableone
JOIN NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA tabletwo
	ON tableone.ParcelID = tabletwo.ParcelID
	AND tableone.[UniqueID ] <> tabletwo.[UniqueID ]
WHERE tableone.PropertyAddress IS NULL
--LOOKS GOOD TO REPLACE

--UPDATE TE ACTUAL TABLE
UPDATE tableone
SET PropertyAddress = ISNULL(tableone.PropertyAddress,tabletwo.PropertyAddress)
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA tableone
JOIN NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA tabletwo
	ON tableone.ParcelID = tabletwo.ParcelID
	AND tableone.[UniqueID ] <> tabletwo.[UniqueID ]
WHERE tableone.PropertyAddress IS NULL
-- AND THERE ARE NO NULL VALUES IN PropertyAddress(CHECK WITH CODE 2 IN THIS SECTION IF NEEDED)

--------------------------------------------------------------------------------------------------------------------------------------
--SPLIT THE PoropertyAddress INTO ADDRESS,CITY
--SEPERATED ON COMMA
SELECT *
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA


--ADD NEW COLUMN Address TO THE TABLE
ALTER TABLE HOUSING_DATA
ADD Address NVARCHAR(255);

--UPDATE THE ADDED COLUMN WITH Address SPLIT FROM PropertyAddress
UPDATE HOUSING_DATA
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

--ADD NEW COLUMN City TO THE TABLE
ALTER TABLE HOUSING_DATA
ADD City NVARCHAR(255);

--UPDATE THE ADDED COLUMN WITH City SPLIT FROM PropertyAddress
UPDATE HOUSING_DATA
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

SELECT PropertyAddress,Address,City
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--------------------------------------------------------------------------------------------------------------------------------------
--SPLIT THE OwnerAddress INTO ADDRESS,CITY,STATE
SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS OwnersAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS OwnersCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS OwnersState
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--ADD NEW COLUMN OwnersAddress TO THE TABLE
ALTER TABLE HOUSING_DATA
ADD OwnersAddress NVARCHAR(255);

--UPDATE THE ADDED COLUMN WITH ADDRESS SPLIT FROM OwnersAddress
UPDATE HOUSING_DATA
SET OwnersAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

--ADD NEW COLUMN TO THE TABLE
ALTER TABLE HOUSING_DATA
ADD OwnersCity NVARCHAR(255);

--UPDATE THE ADDED COLUMN WITH CITY SPLIT FROM OwnersAddress
UPDATE HOUSING_DATA
SET OwnersCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

--ADD NEW COLUMN TO THE TABLE
ALTER TABLE HOUSING_DATA
ADD OwnersState NVARCHAR(255);

--UPDATE THE ADDED COLUMN WITH STATE SPLIT FROM OwnersAddress
UPDATE HOUSING_DATA
SET OwnersState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

SELECT OwnerAddress, OwnersAddress, OwnersCity, OwnersState
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

--------------------------------------------------------------------------------------------------------------------------------------
--IN SoldAsVacant COLUMN THERE ARE Y, N, Yes, No VALUES
SELECT DISTINCT(SoldAsVacant)
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS count_distinct
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
GROUP BY SoldAsVacant
ORDER BY count_distinct
--CHANGE ALL Y TO Yes AND N TO No

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

UPDATE HOUSING_DATA
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
--UPDATE DONE (CHECK WITH CODE 2 IN THIS SECTION IF NEEDED)

--------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE DUPLICATES USING CTE
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
ORDER BY ParcelID
--FIND FOR ROWS WITH row_num 2 AND DELETE THEM
--WE WILL USE CTE TO DELETE THOSE ROWS

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num>1
ORDER BY PropertyAddress
--THERE ARE 104 DUPLICATES IN THE DATA, DELETE THOSE DUPLICATES

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num>1
--DONE, NO MORE DUPLICATES

--------------------------------------------------------------------------------------------------------------------------------------
--DELETE UNUSED COLUMNS, WE GOT THE NECESSARY INFO FROM OwnerrAddress AND PropertyAddress WE WILL DELETE THOSE
SELECT *
FROM NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA

ALTER TABLE NASHVILLE_HOUSING_DATA.dbo.HOUSING_DATA
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate
