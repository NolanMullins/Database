USE [DAC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================
-- Author:		Nolan Mullins
-- Create date: 05/26/2016
-- Description:	--- info line
-- ======================================================
Alter PROCEDURE [dbo].[PricingGetInfoLine] 	@product nvarchar(50), @newPrice float
As
Begin

	declare @ppgCode as nvarchar(50)
	declare @Suffix as nvarchar(50)
	declare @CustomerCode as nvarchar(50)
	declare @numC1 as int
	declare @qty as int

	/*--check for suffix
	set @Suffix = 
	(
		select top 1 CustomerName from [server].[DAC].[dbo].Suffix
		where RIGHT(@product, LEN(Suffix)) = Suffix
		order by LEN(Suffix) desc
	)
	--if this table needs to be populated
	if (@Suffix is null)
	Begin*/
		--get quantity sold in last 12 months
		set @qty = (select	SUM(ShippedQuantity) [Sales] from SalesDetail 
					where	ProductCode = @product and companyid = '002'
							and MONTH(InvoiceDate) >= MONTH(DATEADD( m, -12, GETDATE()))
							and YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE())))
		select 
			@product [Product Code],
			pa.ReplacementCost [Old], 
			@newPrice [New],
			ROUND(@newPrice - pa.ReplacementCost, 5) [DIF], 
			cast(100*((@newPrice-pa.ReplacementCost)/pa.ReplacementCost) as decimal(16,2)) [% chg],
		
			@qty [QTY],
			cast((select	SUM(Ext_Price) [Sales] from SalesDetail 
						where	ProductCode = @product and 
								companyid = '002' and
								MONTH(InvoiceDate) >= MONTH(DATEADD(m, -12, GETDATE()))
								and YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE()))) 							
								as decimal(16,2)) [Total Sales],
								
			cast(@qty * (@newPrice - pa.ReplacementCost) as decimal(16,2)) [Impact]
		
		from ProductAll pa
		where 
			@product = pa.productCode and pa.CompanyID = '002'
		
	--End
End