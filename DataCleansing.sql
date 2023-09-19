/*
In this part, we will clean the data and transform it to use for Sale analysis later
*/

-- 1. NEWDIMDATE
-- Since we only need to use 2 years back.

SELECT	DateKey, 
		FullDateAlternateKey as FullDate,
		EnglishDayNameOfWeek as Namedate,
		left(EnglishMonthName, 3) as MonthShort,
		MonthNumberOfYear as MonthNunber,
		CalendarQuarter as Quarter,
		CalendarYear as Year
FROM DimDateNew
where CalendarYear >= 2020;




-- 2. DIMCUSTOMER
select c.CustomerKey as CustomerKey,
		c.FirstName as FirstName,
		c.LastName as LastName,
		c.FirstName + ' ' + c.LastName as FullName,
		case c.Gender
			when 'M' then 'Male'
			when 'F' then 'Female'
			end as Gender,
		c.NewDFP as DateFirstPurchase,
		g.city as CustomerCity,
		g.EnglishCountryRegionName as CustomerCountry
  FROM DimCustomer c
  left join DimGeography g
  on c.GeographyKey = g.GeographyKey
  order by CustomerKey;


  -- 3. DIMPRODUCT
 select p.ProductKey as ProductKey,
      p.ProductAlternateKey as ProductCode,
      p.EnglishProductName as ProductName,
	  ps.EnglishProductSubcategoryName as Subcategory,
	  pc.EnglishProductCategoryName as Category,
      p.Color as Color,
	  p.Size as Size,
      p.ProductLine as ProductLine,
      p.ModelName as ModelName,
      p.EnglishDescription as ProductDescription,
      isnull(p.Status, 'OutDated') as ProductStatus
FROM DimProduct p
	left join DimProductSubcategory ps 
	on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
	left join DimProductCategory pc
	on ps.ProductCategoryKey = pc.ProductCategoryKey
order by ProductKey;

-- 4. FactInternetSales
select ProductKey,
	NewODK,
	NewDDK,
	NewSDK,
	CustomerKey,
	SalesOrderNumber,
	SalesAmount
FROM FactInternetSales
WHERE left (NewODK, 4) >= 2020 
ORDER BY NewODK;

