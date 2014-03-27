    select distinct author || '/' || archive as authdist
    from xs, archive
    where xs.distribution = archive.distribution
      and xs.version = archive.version;
