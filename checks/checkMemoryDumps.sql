SELECT 
    [filename] as [name], 
    creation_time, 
    size_in_bytes
FROM 
    sys.dm_server_memory_dumps 
WITH (NOLOCK)
OPTION (RECOMPILE);