::Make dir based on date (It wont create a file if no files are found)

>nul 2>nul dir /a-d "server\Helpdesk\VendorPricingTickets\Tickets\Active\*" &&(^
mkDir "server\Helpdesk\VendorPricingTickets\Tickets\Archive\%date:/=_%") ^
|| (echo No files found)

::Move Active files to archive 

>nul 2>nul dir /a-d "server\Helpdesk\VendorPricingTickets\Tickets\Active\*" &&(^
move /-y "server\Helpdesk\VendorPricingTickets\Tickets\Active\*" "server\Helpdesk\VendorPricingTickets\Tickets\Archive\%date:/=_%") ^
|| (echo No files found)

::Run Analysis

del all.csv
for /r "server\Helpdesk\VendorPricingTickets\Tickets\" %%a in (*.csv) do for /f "usebackq tokens=*" %%b in ("%%a") do echo %%b,%%~nxa,%%~ta >> all.csv
MOVE "all.csv" server\User_Specific_Shares\NolanMullins\dump


