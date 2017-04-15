SELECT sc.ScheduleID AS [SQL Agent Job Name]

,c.Name AS ReportName

,sb.[Description] AS [Subscription Description]

,sb.DeliveryExtension AS [Delivery Type]

,sb.LastStatus AS [Last Run Status]

,sb.LastRunTime AS [Last Run Time]

,c.Path AS ReportPath

FROM ReportServer.dbo.ReportSchedule rs

INNER JOIN ReportServer.dbo.Schedule sc ON rs.ScheduleID = sc.ScheduleID

INNER JOIN ReportServer.dbo.Subscriptions sb ON rs.SubscriptionID = sb.SubscriptionID

INNER JOIN ReportServer.dbo.[Catalog] c ON rs.ReportID = c.ItemID AND sb.Report_OID = c.ItemID

WHERE (sb.LastStatus LIKE 'Failure%' OR sb.LastStatus LIKE 'Error%')

--AND sb.LastRunTime > DATEADD(D, -1, GETDATE())