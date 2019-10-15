@{
    ParameterList = @(
        @{
            Name    = 'MaxEnvelopeSizekb'
            Path    = 'MaxEnvelopeSizekb'
            Type    = 'Uint32'
            Default = 500
            TestVal = 501
            IntTest = $true
        },
        @{
            Name    = 'MaxTimeoutms'
            Path    = 'MaxTimeoutms'
            Type    = 'Uint32'
            Default = 60000
            TestVal = 60001
            IntTest = $true
        },
        @{
            Name    = 'MaxBatchItems'
            Path    = 'MaxBatchItems'
            Type    = 'Uint32'
            Default = 32000
            TestVal = 32001
            IntTest = $true
        }
    )
}
