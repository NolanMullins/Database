move /-y *.csv "server\Helpdesk\VendorPricingTickets\Tickets\Active"

DEL all.csv
DEL server\Helpdesk\VendorPricingTickets\Compiled\all.csv
for /r "server\Helpdesk\VendorPricingTickets\Tickets\Active" %%a in (*.csv) do for /f "usebackq tokens=*" %%b in ("%%a") do echo %%b,%%~nxa >> all.csv
MOVE all.csv server\Helpdesk\VendorPricingTickets\Compiled