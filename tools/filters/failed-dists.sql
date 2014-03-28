select distinct autharchive
  from pass
 where passed is not null
   and not passed;
