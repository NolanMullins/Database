exec [server].[DAC].[dbo].getTicketHist

declare @currentWeek as int

set @currentWeek = DATEDIFF(week, '2016-01-04', GETDATE())


select VendorNumber
,VendorName
,data4.[Error Count] [4 Weeks ago]
,data3.[Error Count] [3 Weeks ago]
,data2.[Error Count] [2 Weeks ago]
,data1.[Error Count] [Last Week]
,data.[Error Count] [Current Week]
 from Vend v

left join(
SELECT
Count(tk.ProductCode) [Error Count],
DATEDIFF(week, '2016-01-04', fileTimeStamp) AS WeekNumber,
VendorCode

FROM [server].[DAC].dbo.ticketHist tk
left join ProductAllVendor pav on tk.productCode = pav.ProductCode and pav.CompanyID = '002'
where DATEDIFF(week, '2016-01-04', fileTimeStamp) = @currentWeek
group by VendorCode, DATEDIFF(week, '2016-01-04', fileTimeStamp)
) data on v.VendorNumber = data.vendorCode

left join(
SELECT
Count(tk.ProductCode) [Error Count],
DATEDIFF(week, '2016-01-04', fileTimeStamp) AS WeekNumber,
VendorCode

FROM [server].[DAC].dbo.ticketHist tk
left join ProductAllVendor pav on tk.productCode = pav.ProductCode and pav.CompanyID = '002'
where DATEDIFF(week, '2016-01-04', fileTimeStamp) = @currentWeek-1
group by VendorCode, DATEDIFF(week, '2016-01-04', fileTimeStamp)
) data1 on v.VendorNumber = data1.vendorCode

left join(
SELECT
Count(tk.ProductCode) [Error Count],
DATEDIFF(week, '2016-01-04', fileTimeStamp) AS WeekNumber,
VendorCode

FROM [server].[DAC].dbo.ticketHist tk
left join ProductAllVendor pav on tk.productCode = pav.ProductCode and pav.CompanyID = '002'
where DATEDIFF(week, '2016-01-04', fileTimeStamp) = @currentWeek-2
group by VendorCode, DATEDIFF(week, '2016-01-04', fileTimeStamp)
) data2 on v.VendorNumber = data2.vendorCode

left join(
SELECT
Count(tk.ProductCode) [Error Count],
DATEDIFF(week, '2016-01-04', fileTimeStamp) AS WeekNumber,
VendorCode

FROM [server].[DAC].dbo.ticketHist tk
left join ProductAllVendor pav on tk.productCode = pav.ProductCode and pav.CompanyID = '002'
where DATEDIFF(week, '2016-01-04', fileTimeStamp) = @currentWeek-3
group by VendorCode, DATEDIFF(week, '2016-01-04', fileTimeStamp)
) data3 on v.VendorNumber = data3.vendorCode

left join(
SELECT
Count(tk.ProductCode) [Error Count],
DATEDIFF(week, '2016-01-04', fileTimeStamp) AS WeekNumber,
VendorCode

FROM [server].[DAC].dbo.ticketHist tk
left join ProductAllVendor pav on tk.productCode = pav.ProductCode and pav.CompanyID = '002'
where DATEDIFF(week, '2016-01-04', fileTimeStamp) = @currentWeek-4
group by VendorCode, DATEDIFF(week, '2016-01-04', fileTimeStamp)
) data4 on v.VendorNumber = data4.vendorCode

where v.companyID = '002'
and (data.[Error Count] > 0 or data1.[Error Count] > 0 or data2.[Error Count] > 0 or data3.[Error Count] > 0 or data4.[Error Count] > 0)
order by VendorName