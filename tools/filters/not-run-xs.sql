select path
  from xs, archive, pass
 where xs.distribution = archive.distribution
   and xs.version_numified = archive.version
   and xs.author || '/' || archive.archive = ?
   and path not in 
    ( select path
        from pass
       where pass.distribution = ?
    )
;