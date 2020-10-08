# ee-api

Using [Eve Echoes Market API](https://eve-echoes-market.com/api) this will
ultimately store historical data for future perusal.

Working now:
 - downloading of data
 - caching of data
 - connect to db
 - update db when downloading data
 - convert from open(D,"ftp -o - ${URL}|") to perl native web retrieval
 - check stat() equivalent on data to see if newer is avail, don't bother retrieving if not
   ... HEAD and reading 'Last-Modified' header, save, compare with previous check

Note:
 - disk cache only grows, but is updated as HEAD checks show new versions of files is avail

Future work:
 - periodically poll for new data
 - use perl native compression/decompression
 - save hash of $res->content .. if seen before, skip processing
 - only save new hash if completed processing
