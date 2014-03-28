    select distinct author || '/' || archive as authdist
    from xs, archive
    where xs.release = ?
      and xs.distribution = archive.distribution
      and xs.version = archive.version;
