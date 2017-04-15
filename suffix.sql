USE [DAC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================
-- Author:		Nolan Mullins
-- Create date: 05/26/2016
-- Description:	Suffix data
-- ======================================================
Alter PROCEDURE [dbo].[PricingGetSuffixData] 	@product nvarchar(50), @newPrice float
As
Begin

	declare @ppgCode as nvarchar(50)
	declare @Suffix as nvarchar(50)
	declare @CustomerCode as nvarchar(50)
	declare @numC1 as int
	declare @qty as int

	--get suffix
	set @Suffix = 
	(
		select top 1 CustomerName from [server].[DAC].[dbo].Suffix
		where RIGHT(@product, LEN(Suffix)) = Suffix
		order by LEN(Suffix) desc
	)
	--if this table needs to be populated
	if (@Suffix is not null)
	Begin
		set @CustomerCode = (	select top 1 AcctCode from [server].[DAC].[dbo].Suffix
								where RIGHT(@product, LEN(Suffix)) = Suffix
								order by LEN(Suffix) desc
							)
		
		set @qty = (	select	SUM(ShippedQuantity) [Sales] from SalesDetail 
						where	CustomerCode = @CustomerCode and ProductCode = @product and companyid = '002'
								and MONTH(InvoiceDate) >= MONTH(DATEADD( m, -12, GETDATE()))
								and YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE()))
					)
		
		select top 1
		@product [Product Code],
		pa.ProductDescription1,
		pa.ReplacementCost [Old], 
		@newPrice [New],
		ROUND(@newPrice - pa.ReplacementCost, 5) [DIF], 
		cast(100*((@newPrice-pa.ReplacementCost)/pa.ReplacementCost) as decimal(16,2)) [% chg],
		
		@qty [QTY],
		--Sum of sales in the past 12 months for the customer on X line
		cast((select	SUM(Ext_Price) [Sales] from SalesDetail 
						where	CustomerCode = @CustomerCode and 
								ProductCode = @product and 
								companyid = '002' and
								MONTH(InvoiceDate) >= MONTH(DATEADD(m, -12, GETDATE()))
								and YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE()))) 							
								as decimal(16,2)) [Cust Sales],
		
		cast(@qty * (@newPrice - pa.ReplacementCost) as decimal(16,2)) [Impact],
		@Suffix [Suffix],
		c1s.PriceCalcMethod [C1],
		c5s.PriceCalcMethod [C5],
		p.ContractFlag [Has Contract],
		p.ContractNumber,
		v.VendorName,
		p.VendorContractNumber [Vendor Contract Number],
		p.Cost [Contract Cost],
		s.Description [Email]
		------------------------------------------------------------------------------------------------------------------------------------
		from ProductAll pa
		------------------------------------------------------------------------------------------------------------------------------------
		left join SalesDetail sd on sd.CustomerCode = @CustomerCode and pa.ProductCode = sd.ProductCode and pa.companyid = sd.companyid
		------------------------------------------------------------------------------------------------------------------------------------
		--GET C1 DATA
		left join (select PriceCalcMethod, Value1, Value2 from Price
		where CompanyCode = '002'
		and @product = Value2
		and @CustomerCode = Value1
		and (ExpiryDate > GETDATE() or ExpiryDate is null)
		and PriceMatrixType = '1' ) c1s on c1s.Value2 = pa.ProductCode 
		------------------------------------------------------------------------------------------------------------------------------------
		--GET C5 DATA
		left join (select PriceCalcMethod from Price p
		left join ProductAll pa on p.Value2 = pa.ProductPriceGroup 
		where CompanyCode = '002'
		and pa.ProductCode = @product
		and (ExpiryDate > GETDATE() or ExpiryDate is null)
		and p.Value1 = @CustomerCode) c5s on 1=1
		------------------------------------------------------------------------------------------------------------------------------------
		--Various other data
		left join Price p on pa.ProductCode = p.Value1
		left join Customer c on @CustomerCode = c.customerCode
		left join Salesman s on c.SalesRepOne = s.SalesmanID
		left join ProductAllVendor pav on pa.ProductCode = pav.productCode
		left join Vend v on pav.VendorCode = v.VendorNumber
		------------------------------------------------------------------------------------------------------------------------------------
		where pa.CompanyID = '002' and pa.ProductCode = @product
		------------------------------------------------------------------------------------------------------------------------------------
	End
End