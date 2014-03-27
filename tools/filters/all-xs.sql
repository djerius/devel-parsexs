select path
  from xs, archive
 where xs.distribution = archive.distribution
   and xs.version_numified = archive.version
   and xs.author || '/' || archive.archive = ?
;