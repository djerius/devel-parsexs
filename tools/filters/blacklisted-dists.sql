select distinct autharchive
  from pass
 where path is null
   and passed is null;
