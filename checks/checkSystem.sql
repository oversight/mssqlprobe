SELECT
    SERVERPROPERTY('MachineName') AS [MachineName],
    SERVERPROPERTY('ServerName') AS [ServerName],
    SERVERPROPERTY('ServerName') AS [name],
    SERVERPROPERTY('InstanceName') AS [Instance],
    SERVERPROPERTY('IsClustered') AS [IsClustered],
    SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS],
    SERVERPROPERTY('Edition') AS [Edition],
    SERVERPROPERTY('ProductLevel') AS [ProductLevel],				-- What servicing branch (RTM/SP/CU)
    SERVERPROPERTY('ProductUpdateLevel') AS [ProductUpdateLevel],	-- Within a servicing branch, what CU# is applied
    SERVERPROPERTY('ProductVersion') AS [ProductVersion],
    SERVERPROPERTY('ProductMajorVersion') AS [ProductMajorVersion],
    SERVERPROPERTY('ProductMinorVersion') AS [ProductMinorVersion],
    SERVERPROPERTY('ProductBuild') AS [ProductBuild],
    SERVERPROPERTY('ProductBuildType') AS [ProductBuildType],		      -- Is this a GDR or OD hotfix (NULL if on a CU build)
    SERVERPROPERTY('ProductUpdateReference') AS [ProductUpdateReference], -- KB article number that is applicable for this build
    SERVERPROPERTY('ProcessID') AS [ProcessID],
    SERVERPROPERTY('Collation') AS [Collation],
    SERVERPROPERTY('IsFullTextInstalled') AS [IsFullTextInstalled],
    SERVERPROPERTY('IsIntegratedSecurityOnly') AS [IsIntegratedSecurityOnly],
    SERVERPROPERTY('FilestreamConfiguredLevel') AS [FilestreamConfiguredLevel],
    SERVERPROPERTY('IsHadrEnabled') AS [IsHadrEnabled],
    SERVERPROPERTY('HadrManagerStatus') AS [HadrManagerStatus],
    SERVERPROPERTY('InstanceDefaultDataPath') AS [InstanceDefaultDataPath],
    SERVERPROPERTY('InstanceDefaultLogPath') AS [InstanceDefaultLogPath],
    SERVERPROPERTY('BuildClrVersion') AS [BuildClrVersion],
    windows_release,
    windows_service_pack_level,
    windows_sku,
    os_language_version
FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);