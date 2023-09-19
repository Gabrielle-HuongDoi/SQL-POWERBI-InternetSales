  /*
  
  Description
  ---- The AdventureWork has original database from 2010 to 2014. So this script will shift the records to 2018 - 2022.
  ---- It would rather leap the datebase to the multiple of 4 years to avoid the constraint issues
  
  */
 


 ---- 1. FIRST OF ALL, CHECK ALL THE DATE FORMATTINGS, FIRST DATE AND LAST DATE RECORDED IN THE TABLES
 select MIN(DateFirstPurchase) as first_date, MAX(DateFirstPurchase) as last_date
 from DimCustomer;


 select MIN(StartDate) as first_date, MAX(EndDate) as last_date
 from DimPromotion;

 ---- Some tables have Date and Datekey formattings:
 ---- FactCallCenter, FactCurrencyRate, FactFinance, FactInternetSales, FactInternetSalesReason, FactProductInventory, FactResellerSales, FactSalesQuota, FactSurveyResponse,

 select MIN(Date) as first_date, MAX(Date) as last_date, MIN(DateKey) as first_datekey, MAX(DateKey) as last_datekey
 from FactCallCenter;

 select MIN(Date) as first_date, MAX(Date) as last_date, MIN(DateKey) as first_datekey, MAX(DateKey) as last_datekey
 from FactCurrencyRate;


  ---- So the time range is from 2010 to 2014, there are a few date columns such as birth date, hired date not to be updated.


  ---------------------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------------------

 ---- 2. DROP THE FOREIGN KEYS (only foreign keys refering to date)
alter table FactCallCenter drop constraint FK_FactCallCenter_DimDate;
alter table FactCurrencyRate drop constraint FK_FactCurrencyRate_DimDate;
alter table FactFinance drop constraint FK_FactFinance_DimDate;
alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate;
alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate1;
alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate2;
alter table FactProductInventory drop constraint FK_FactProductInventory_DimDate;
alter table FactResellerSales drop constraint FK_FactResellerSales_DimDate;
alter table FactSurveyResponse drop constraint FK_FactSurveyResponse_DateKey;


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

---- 3. CREATE NEW DIMDATE TABLE
drop table if exists DimDateNew;

create table DimDateNew (
	DateKey int,
	FullDateAlternateKey date,
	DayNumberOfWeek tinyint,
	EnglishDayNameOfWeek nvarchar(10),
	DayNumberOfMonth tinyint,
	DayNumberOfYear smallint,
	WeekNumberOfYear tinyint,
	EnglishMonthName nvarchar(10),
	MonthNumberOfYear tinyint,
	CalendarQuarter tinyint,
	CalendarYear smallint,
	CalendarSemester tinyint,
	FiscalQuarter tinyint,
	FiscalYear int,
	FiscalSemester tinyint
);

--declare the local variable for the date recursion
declare @startdate date = '2018-01-01', 
	@enddate date = '2022-12-31';


--make recursion
with date_cte as (
	select @startdate as FullDate
	union all
	select CONVERT(date, DATEADD(day, 1, FullDate)) as FullDate
	from date_cte
	where date_cte.FullDate < @enddate
)
	--check before insert values to DimDateNew table: select top(10) * from date_cte
insert into DimDateNew (FullDateAlternateKey)
select *
from date_cte
option (maxrecursion 0);


--populate the new date dimension
update DimDateNew 
set DateKey = cast(convert(varchar, FullDateAlternateKey, 112) as int),
	DayNumberOfWeek = datepart(WEEKDAY, FullDateAlternateKey),
	EnglishDayNameOfWeek = DATENAME(WEEKDAY, FullDateAlternateKey),
	DayNumberOfMonth = DATEPART(day, FullDateAlternateKey),
	DayNumberOfYear = DATEPART(DAYOFYEAR, FullDateAlternateKey),
	WeekNumberOfYear = DATEPART(WEEK, FullDateAlternateKey),
	EnglishMonthName = DATENAME(MONTH, FullDateAlternateKey),
	MonthNumberOfYear = MONTH(FullDateAlternateKey),
	CalendarQuarter = DATEPART(QUARTER, FullDateAlternateKey),
	CalendarYear = YEAR(FullDateAlternateKey),
	CalendarSemester = case DATEPART(QUARTER, FullDateAlternateKey)
						when 1 then 1
						when 2 then 1
						when 3 then 2
						when 4 then 2
						end,
	FiscalQuarter = case DATEPART(QUARTER, FullDateAlternateKey)  
						when 1 then 3  
						when 2 then 4  
						when 3 then 1  
						when 4 then 2
						end,
	FiscalYear = case DATEPART(QUARTER, FullDateAlternateKey)
					when 1 then YEAR(FullDateAlternateKey) - 1
					when 2 then YEAR(FullDateAlternateKey) - 1
					when 3 then YEAR(FullDateAlternateKey)
					when 4 then year(FullDateAlternateKey)
					end,
	FiscalSemester = case DATEPART(QUARTER, FullDateAlternateKey)
						when 1 then 2
						when 2 then 2
						when 3 then 1
						when 4 then 1
						end
;


-- Set the constraints
alter table DimDateNew alter column DateKey int not null; 
alter table DimDateNew alter column FullDateAlternateKey date not null;
alter table DimDateNew add constraint PK_DimDateNew_Datekey primary key (DateKey);

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

--- 4. UPDATE THE DATE AND DATEKEY
alter table DimCustomer add NewDFP date;
update DimCustomer
set NewDFP = coalesce(dateadd(year, 8, DateFirstPurchase), null);


alter table DimEmployee add NewStartDate date, NewEndDate date;
update DimEmployee
set NewStartDate = coalesce(dateadd(year, 8, StartDate), null),
	NewEndDate = coalesce(dateadd(year, 8, EndDate), null);


alter table DimProduct add NewStartDate date, NewEndDate date;
update DimProduct
set NewStartDate = coalesce(dateadd(year, 8, StartDate), null),
	NewEndDate = coalesce(dateadd(year, 8, EndDate), null);


alter table DimPromotion add NewStartDate date, NewEndDate date;
update DimPromotion
set NewStartDate = coalesce(dateadd(year, 8, StartDate), null),
	NewEndDate = coalesce(dateadd(year, 8, EndDate), null);


alter table FactCallCenter add NewDate date, NewDateKey int;
update FactCallCenter
set NewDate = coalesce(dateadd(year, 8, Date), null);
update FactCallCenter
set	NewDateKey = case 
					when NewDate is not null then cast(convert(varchar, NewDate, 112) as int) 
					end;


alter table FactCurrencyRate add NewDate date, NewDateKey int;
update FactCurrencyRate
set NewDate = coalesce(dateadd(year, 8, Date), null);
update FactCurrencyRate
set NewDateKey = case 
					when NewDate is not null then cast(convert(varchar, NewDate, 112) as int)
					end;


alter table FactFinance add NewDate date, NewDateKey int;
update FactFinance
set NewDate = coalesce(dateadd(year, 8, Date), null);
update FactFinance
set NewDateKey = case 
					when NewDate is not null then cast(convert(varchar, NewDate, 112) as int)
					end;


alter table FactInternetSales add NewOrderDate date, NewDueDate date, NewShipDate date;
update FactInternetSales
set NewOrderDate = coalesce(dateadd(year, 8, OrderDate), null),
	NewDueDate = coalesce(dateadd(year, 8, DueDate), null),
	NewShipDate= coalesce(dateadd(year, 8, ShipDate), null);

alter table FactInternetSales add NewODK int, NewDDK int, NewSDK int;
update FactInternetSales
set NewODK = coalesce(cast(convert(varchar, NewOrderDate, 112) as int), null),
	NewDDK = coalesce(cast(convert(varchar, NewDueDate, 112) as int), null),
	NewSDK = coalesce(cast(convert(varchar, NewShipDate, 112) as int), null);


alter table FactProductInventory add NewMD date, NewDateKey int;
update FactProductInventory
set NewMD = coalesce(dateadd(year, 8, MovementDate), null);
update FactProductInventory
set NewDateKey = case 
					when NewMD is not null then cast(convert(varchar, NewMD, 112) as int)
					end;


alter table FactResellerSales add NewOrderDate date, NewDueDate date, NewShipDate date;
update FactResellerSales
set NewOrderDate = coalesce(dateadd(year, 8, OrderDate), null),
	NewDueDate = coalesce(dateadd(year, 8, DueDate), null),
	NewShipDate= coalesce(dateadd(year, 8, ShipDate), null);

alter table FactResellerSales add NewODK int, NewDDK int, NewSDK int;
update FactResellerSales
set NewODK = coalesce(cast(convert(varchar, NewOrderDate, 112) as int), null),
	NewDDK = coalesce(cast(convert(varchar, NewDueDate, 112) as int), null),
	NewSDK = coalesce(cast(convert(varchar, NewShipDate, 112) as int), null);

	
alter table FactSalesQuota add NewDate date, NewDateKey int;
update FactSalesQuota
set NewDate = coalesce(dateadd(year, 8, Date), null);
update FactSalesQuota
set NewDateKey = case 
					when NewDate is not null then cast(convert(varchar, NewDate, 112) as int)
					end;

alter table FactSurveyResponse add NewDate date, NewDateKey int;
update FactSurveyResponse
set NewDate = coalesce(dateadd(year, 8, Date), null);
update FactSurveyResponse
set NewDateKey = case
					when NewDate is not null then cast(convert(varchar, NewDate, 112) as int)
					end;


-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- 5. ADD BACK CONSTRAINTS
alter table FactCallCenter 
	with check add constraint FK_FactCallCenter_NewDimDate
	foreign key (NewDateKey) references DimDateNew(DateKey);

alter table FactCurrencyRate 
	with check add constraint FK_FactCurrencyRate_NewDimDate
	foreign key (NewDateKey) references DimDateNew(DateKey);

alter table FactFinance 
	with check add constraint FK_FactFinance_NewDimDate
	foreign key (NewDateKey) references DimDateNew(DateKey);


alter table FactInternetSales 
	with check add constraint FK_FactInternetSales_NewDimDate
	foreign key (NewODK) references DimDateNew(DateKey);

alter table FactInternetSales 
	with check add constraint FK_FactInternetSales_NewDimDate1
	foreign key (NewDDK) references DimDateNew(DateKey);

alter table FactInternetSales 
	with check add constraint FK_FactInternetSales_NewDimDate2
	foreign key (NewSDK) references DimDateNew(DateKey);

alter table FactProductInventory 
	with check add constraint FK_FactProductInventory_NewDimDate
	foreign key (NewDateKey) references DimDateNew(DateKey);

alter table FactResellerSales 
	with check add constraint FK_FactResellerSales_NewDimDate
	foreign key (NewODK) references DimDateNew(DateKey);

alter table FactSurveyResponse 
	with check add constraint FK_FactSurveyResponse_DateKey
	foreign key (NewDateKey) references DimDateNew(DateKey);














