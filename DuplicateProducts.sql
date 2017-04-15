
select * from (  
select COUNT(ID) [c], ID from (
select pav.VendorProductCode+'-'+pav.VendorCode [ID]
from ProductAllVendor pav
left join ProductAll pa on pav.ProductCode = pa.ProductCode and pav.CompanyID = pa.CompanyID
left join
		(
			select suf.Suffix , suf.CustomerName [Customer],tk.productCode [pCode], s.Description [SalesRep] from [server].[DAC].[dbo].Suffix suf
			
			left join (select case 
									when EXISTS (select * from [server].[DAC].[dbo].Suffix where Suffix = RIGHT(productCode, 3))
									then RIGHT(productCode, 3)
									when EXISTS (select * from [server].[DAC].[dbo].Suffix where Suffix = RIGHT(productCode, 2))
									then RIGHT(productCode, 2)
									else ''
								end as [ProductSuffix],productCode 
						from  ProductAll
						where not ObsoleteFlag = 'y' and CompanyID = '002'
						) tk 
			on tk.productsuffix = suf.suffix
			--left join SalesDetail sd on sd.CustomerCode = suf.AcctCode and tk.productCode = sd.ProductCode and '002' = sd.companyid
			left join Customer c on suf.AcctCode = c.customerCode and c.CompanyID = '002'
			left join Salesman s on c.SalesRepOne = s.SalesmanID and c.CompanyID = s.CompanyID
			--order by LEN(Suffix) desc
		) suf on pav.productCode = suf.pCode	
where 
pav.CompanyID = '002'
and suf.Suffix is null
and not left(pav.productCode, 1) = '*'
and not VendorProductCode is null
and not obsoleteFlag = 'y'
and not CHARINDEX('.', pav.productCode) > 0
and not CHARINDEX('-', pav.productCode) > 0
) temp
group by ID
) data
left join ProductAllVendor pav on LEFT(ID, charindex('-', ID)-1) = pav.VendorProductCode and  RIGHT(ID, Len(ID)-charindex('-', ID)) = pav.VendorCode and pav.CompanyID = '002'
left join ProductAll pa on pav.ProductCode = pa.ProductCode and pa.CompanyID = pav.CompanyID
left join
		(
			select suf.Suffix , suf.CustomerName [Customer],tk.productCode [pCode], s.Description [SalesRep] from [server].[DAC].[dbo].Suffix suf
			
			left join (select case 
									when EXISTS (select * from [server].[DAC].[dbo].Suffix where Suffix = RIGHT(productCode, 3))
									then RIGHT(productCode, 3)
									when EXISTS (select * from [server].[DAC].[dbo].Suffix where Suffix = RIGHT(productCode, 2))
									then RIGHT(productCode, 2)
									else ''
								end as [ProductSuffix],productCode 
						from  ProductAll
						where not ObsoleteFlag = 'y' and CompanyID = '002'
						) tk 
			on tk.productsuffix = suf.suffix
			--left join SalesDetail sd on sd.CustomerCode = suf.AcctCode and tk.productCode = sd.ProductCode and '002' = sd.companyid
			left join Customer c on suf.AcctCode = c.customerCode and c.CompanyID = '002'
			left join Salesman s on c.SalesRepOne = s.SalesmanID and c.CompanyID = s.CompanyID
			--order by LEN(Suffix) desc
		) suf on pav.productCode = suf.pCode	
where c > 1
and suf.Suffix is null
and not left(pav.productCode, 1) = '*'
and not VendorProductCode is null
and not obsoleteFlag = 'y'
--group by c, ID
order by c desc, ID