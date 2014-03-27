select distinct author || '/' || archive as authdist
    from xs, archive
    where xs.distribution = archive.distribution
      and xs.version_numified = archive.version
      and 
        ( select count(*) from xs where distribution = archive.distribution )
	!= ( select count(*) distribution from pass where distribution = authdist )
;

