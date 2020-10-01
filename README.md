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
 - convert from open(D,"ftp -o - ${URL}|") to perl native web retrieval
   - then check stat() equivalent on data to see if newer is avail, don't bother retrieving if not
