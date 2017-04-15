USE [DAC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================
-- Author:		Nolan Mullins
-- Create date: 05/26/2016
-- Description:	--- Data
-- ======================================================
Create PROCEDURE [dbo].[PricingGetC1Data] 	@product nvarchar(50), @newPrice float
As
Begin

	declare @ppgCode as nvarchar(50)
	declare @Suffix as nvarchar(50)
	declare @CustomerCode as nvarchar(50)
	declare @numC1 as int
	declare @qty as int

	--check for suffix
	set @Suffix = 
	(
		select top 1 CustomerName from [server].[DAC].[dbo].Suffix
		where RIGHT(@product, LEN(Suffix)) = Suffix
		order by LEN(Suffix) desc
	)
	--if this table needs to be populated
	if (@Suffix is null)
	Begin
		--number of C1s
		set @numC1 = (select COUNT(CompanyCode) from Price where CompanyCode = '002'and @product = Value2 and (ExpiryDate > GETDATE() or ExpiryDate is null)and PriceMatrixType = '1')
		
		if (@numC1 > 0)
		Begin
		
			select 
				--Sales (12 Months)
				(select SUM(Ext_Price) [Sales] 
						from SalesDetail sd 
						where 
								p.Value1 = sd.CustomerCode and  
								ProductCode = @product and 
								companyid = '002' and
								MONTH(InvoiceDate) >= MONTH(DATEADD(m, -12, GETDATE())) and
								YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE()))
								) [Sales],
				--Shipped QTY (12 Months)
				(select SUM(ShippedQuantity) [Sales] 
						from SalesDetail sd 
						where 
								p.Value1 = sd.CustomerCode and  
								ProductCode = @product and 
								companyid = '002' and
								MONTH(InvoiceDate) >= MONTH(DATEADD(m, -12, GETDATE())) and
								YEAR(InvoiceDate) >= YEAR(DATEADD(m, -12, GETDATE()))
								) [qty],
			
				PriceCalcMethod [C1],
				p.ContractFlag [Has Contract],
				p.ContractNumber,
				p.VendorContractNumber [Vendor Contract Number],
				p.Cost [Contract Cost],
				Value1 [Cust #], c.CustomerName, s.[Description] [Email] 
			from Price p
				left join Customer c on p.Value1 = c.CustomerCode and c.CompanyID = '002'
				left join salesman s on c.SalesRepOne = s.SalesmanID and c.companyid = s.companyid
		
			where CompanyCode = '002'
				and @product = Value2
				and (ExpiryDate > GETDATE() or ExpiryDate is null)
				and PriceMatrixType = '1'
			
		End
	End
End