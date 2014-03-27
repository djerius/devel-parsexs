insert into authdist
     select distinct author || '/' || archive 
    from xs, archive
    where
         xs.distribution = archive.distribution
;
