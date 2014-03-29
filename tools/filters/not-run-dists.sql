select distinct autharchive
        from
(select path, autharchive
  from files
  except
  select files.path, files.autharchive
    from files, pass
    where files.autharchive = pass.autharchive
      and files.path = pass.path)
;

