select path
  from files
   where autharchive = ?
   and  path not in
    ( select path
        from pass
       where pass.autharchive = ?
    )
;