USE PortfolioProject

SELECT * FROM NashvilleHousing

-- ***CLEANING DATA WITH SQL QUERIES***


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Data Format

SELECT SaleDate, CONVERT(Date,SaleDate) 
	FROM dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
	ADD SaleDateConverted DATE

UPDATE NashvilleHousing
	SET SaleDateConverted = CONVERT(Date, SaleDate)

--------------------------------------------------------------------------------------------------------------------------

-- Populate PropertyAddress Data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM dbo.NashvilleHousing AS a
	JOIN dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID AND a.[UniqueID ] != b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL

UPDATE a
	SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM dbo.NashvilleHousing AS a
	JOIN dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID AND a.[UniqueID ] != b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns

-- 1. Property Address (Using SUBSTRING)

SELECT PropertyAddress FROM NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
	ADD PropertySplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
	SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
	ADD PropertySplitCity NVARCHAR (255)

UPDATE NashvilleHousing
	SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
	

-- 2. Owner Address (Using PARSENAME)

SELECT OwnerAddress FROM NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
	ADD OwnerSplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
	SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
	ADD OwnerSplitCity NVARCHAR (255)

UPDATE NashvilleHousing
	SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
	ADD OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
	SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as vacant" field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant) AS Count FROM NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY Count

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END
	FROM NashvilleHousing

UPDATE NashvilleHousing
	SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END
--------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS 
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS Row_Num FROM NashvilleHousing
)

DELETE FROM RowNumCTE
	WHERE Row_Num > 1

--------------------------------------------------------------------------------------------------------------------------

-- Delete unused Columns

ALTER TABLE NashvilleHousing
	DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--------------------------------------------------------------------------------------------------------------------------
