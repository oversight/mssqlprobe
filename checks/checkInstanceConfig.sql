SELECT 
    name, 
    value, 
    value_in_use, 
    minimum, 
    maximum, 
    [description], 
    is_dynamic, 
    is_advanced
FROM 
    sys.configurations 
WITH (NOLOCK)
OPTION (RECOMPILE);