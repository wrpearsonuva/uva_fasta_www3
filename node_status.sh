#!/bin/csh -f 

set file = /var/www/tmp/logs/node_status.log
while ( -e $file )
  ./node_status.pl > $file
#  echo "updated " `date`
  sleep 60
end
