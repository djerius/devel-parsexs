select distinct author || '/' || archive as authdist
    from xs, archive
    where xs.distribution = archive.distribution
      and xs.version_numified = archive.version
      and authdist not in ( select distribution from pass )
;

