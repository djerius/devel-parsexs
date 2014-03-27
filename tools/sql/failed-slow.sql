    select distinct author || '/' || archive as authdist
    from xs, archive, pass
    where
         xs.distribution = archive.distribution
    and  pass.distribution = authdist
    and  not pass.passed;
