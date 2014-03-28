select path
  from pass
   where autharchive = ?
     and passed is not null
     and not passed
;