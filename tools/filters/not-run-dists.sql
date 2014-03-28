select distinct autharchive
    from files
    where not in ( select autharchive
                     from pass
		     where autharchive = files.autharchive
		       and pass is null )
      and ( select count(*)
              from files
	     where autharchive = files.authdist )
	!= ( select count(*)
	       from pass
	      where autharchive = files.authdist )
;

