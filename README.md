# ee-api

Using [Eve Echoes Market API](https://eve-echoes-market.com/api) this will
ultimately store historical data for future perusal.

Working now:
 - downloading of data
 - caching of data

Note:
 - cache presently does not expire unless manually removed to avoid slamming
   the api site while developing the code

Future work:
 - connect to db
 - update db when downloading data
 - periodically poll for new data
