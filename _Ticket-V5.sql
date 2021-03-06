USE [DAC]
GO
/****** Object:  StoredProcedure [dbo].[helpDeskVendorPricing]    Script Date: 5/31/2016 11:19:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[helpDeskVendorPricing] 
as
/* Price Discrenancy ticket
 * List Price updates
 * Nolan Mullins
 * 12/05/2016
*************************************/
declare @PCHG as float
declare @IMAX as float
/************************************/

/************************************/
set @PCHG = ---
set @IMAX = ---
/************************************/
 
 exec [server].[dac].dbo.[getVendorPriceTicket_List]
         

         select
		--#region [Select]
				tk.productCode,
				
				pa.ReplacementCost [Old], 
				tk.newPrice [New],
				ROUND(tk.newPrice - pa.ReplacementCost, 5) [DIF], 
				cast(100*((tk.newPrice-pa.ReplacementCost)/pa.ReplacementCost) as decimal(16,2)) [% chg],
	
				cast(coalesce(qt.qty, 0) as decimal(16,2)) [QTY],
				cast(coalesce(totalsales,0) as decimal(16,2)) [Total Sales],
							
				cast(coalesce(qt.qty * (tk.newPrice - pa.ReplacementCost) ,0) as decimal(16,2)) [Impact],
				
				coalesce(suf.Customer, '-')[Customer],
				
				--#region [What to do]
				case
					when  cast(100*((tk.newPrice-pa.ReplacementCost)/pa.ReplacementCost) as decimal(16,2)) = 0
					then 'No change needed'
					
					when isNULL(suf.Customer, 'test') = 'test'
					then
						-- % CHG < X && I < 
						case
							when	cast(coalesce(100*((tk.newPrice-pa.ReplacementCost)/pa.ReplacementCost),0) as decimal(16,2)) < @PCHG 
									or cast(coalesce(qt.qty * (tk.newPrice - pa.ReplacementCost),0) as decimal(16,2)) < @IMAX
								then 'Update the Price'
							else 'Large INC detected contact ---' end  
					when isNULL(suf.Customer, 'test') = suf.Customer
						then
						--Has suffix
						case
							when ISNULL(c1.[Contract Cost],0)=0 and ISNULL(c5.[Contract Cost],0)=0
								then 'You need to find a contract, salesrep: '+ coalesce(suf.[SalesRep], '(not found)')
							when not c1.[Contract Cost] = tk.newPrice
									then 'As per contract price is: '+cast(c1.[Contract Cost] as varchar(10))+', reject price change'
							when c1.[Contract Cost] = tk.newPrice
								then 'New cost matches contract, update price' 
							
							else 'Suffixed item' end
						
					
				else '...' end as [What to do],
				--#endregion
		
				c5.[C5] [C5 MatrixType], c5.sales [C5 Sales], c5.qty [C5 QTY], c5.CustomerName [C5 Customer], c5.Email [C5 Email],--  [Has Contracy],
		
				c1.[C1] [C1 MatrixType], c1.sales [C1 Sales], c1.qty [C1 QTY], c1.[CustName] [C1 Customer], c1.Email [C1 Email]
		
--#endregion
         
		 from [server].[dac].dbo.ticket tk
         
		--#region [get the qty sold for the product]
         left join 
				
				(select	SUM(ShippedQuantity) [qty],SUM(ext_price) [totalsales], ProductCode from SalesDetail 
				where	companyid = '002'
						and InvoiceDate >= DATEADD( m, -12, GETDATE())
						
				group by ProductCode) 
				[qt] on tk.productCode = qt.ProductCode
		 --#endregion		
		
		--#region [ProductAll]
		left join ProductAll 
				pa on tk.productCode = pa.ProductCode
				and pa.CompanyID = '002' --added by yo
		--#endregion
		--#region [Join the suffix info] 
		left join
		(
			select suf.Suffix , suf.CustomerName [Customer],tk.productCode [pCode], s.Description [SalesRep] from [server].[DAC].[dbo].Suffix suf
			
			left join (select case 
								when ISNUMERIC(Right(left(productCode,3),1))=1
								then RIGHT(productCode, 2)
								when ISNUMERIC(Right(left(productCode,3),1))=0
								then RIGHT(productCode, 3)
								end as [ProductSuffix],productCode 
						from  [server].[dac].dbo.ticket) tk 
			on tk.productsuffix = suf.suffix
			--left join SalesDetail sd on sd.CustomerCode = suf.AcctCode and tk.productCode = sd.ProductCode and '002' = sd.companyid -- removed by yo
			left join Customer c on suf.AcctCode = c.customerCode and c.CompanyID = '002'
			left join Salesman s on c.SalesRepOne = s.SalesmanID and c.CompanyID = s.CompanyID
			--order by LEN(Suffix) desc
		) suf on tk.productCode = suf.pCode	
		--#endregion
		--#region [C1 Data]
		left join (
			select 
				[Sales],
			    [qty],
				tk.productCode [pCode],
				PriceCalcMethod [C1],
				p.ContractFlag [Has Contract],
				p.ContractNumber,
				coalesce(p.VendorContractNumber, p.VendorQuoteNumber) [Vendor Contract Number],
				p.Cost [Contract Cost],
				Value1 [CustomerNum], c.CustomerName [CustName], s.[Description] [Email] 
			from Price p
				left join Customer c on p.Value1 = c.CustomerCode and c.CompanyID = '002'
				left join salesman s on c.SalesRepOne = s.SalesmanID and c.companyid = s.companyid
				left join [server].[dac].dbo.ticket tk on p.Value2 = tk.productCode
				---
				left join(select SUM(Shippedquantity) [qty],
								 SUM(ext_price)[sales],
								 CustomerCode, 
								 ProductCode,
								 companyid
						  from SalesDetail
						  where InvoiceDate >= DATEADD(m, -12, GETDATE()) 
						  group by CustomerCode, 
								   ProductCode,
								   companyid   )sd on sd.CustomerCode = p.Value1 and sd.ProductCode = tk.productCode
				and c.CompanyID = sd.companyid
				---
			where CompanyCode = '002'
				and (ExpiryDate > GETDATE() or ExpiryDate is null)
				and sd.sales > 0
				and PriceMatrixType = '1'
		) c1 on c1.pCode = tk.productCode
		--#endregion
		--#region [C5 Data]
		left join
		(
			select 
				[Sales],
			    [qty],
			    PriceCalcMethod [C5],
				p.ContractFlag [Has Contract],
				p.ContractNumber,
				p.VendorContractNumber [Vendor Contract Number],
				p.Cost [Contract Cost],
				Value1 [CustomerNum], c.CustomerName, s.[Description] [Email] ,
				tk.productCode [pCode]
			from Price p
				left join Customer c on p.Value1 = c.CustomerCode and c.CompanyID = '002'
				left join salesman s on c.SalesRepOne = s.SalesmanID and c.companyid = s.companyid
				left join ProductAll pa on p.Value2 = pa.ProductPriceGroup
				left join [server].[dac].dbo.ticket tk on pa.ProductCode = tk.productCode
				---
				left join(select SUM(Shippedquantity) [qty],
								 SUM(ext_price)[sales],
								 CustomerCode, 
								 ProductPriceGroup,
								 companyid
						  from SalesDetail
						  where InvoiceDate >= DATEADD(m, -12, GETDATE()) 
						  group by CustomerCode, 
								   ProductPriceGroup,
								   companyid)sd on sd.CustomerCode = p.Value1 and sd.ProductPriceGroup = PA.ProductPriceGroup
				and c.CompanyID = sd.companyid
				---
			where C.CompanyID = '002'
				and (ExpiryDate > GETDATE() or ExpiryDate is null)
				and sd.sales > 0
				and PriceMatrixType = '5'
		) c5 on tk.productCode = c5.pCode
		--#endregion
		where
        --remove the header if there is one
        not (tk.productCode like '%Product%')

	order by productcode,[What to do]

         
         
