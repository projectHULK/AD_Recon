function Get-BrowserHistory {
    <#
    .SYNOPSIS
        Gets web browsing history
    .DESCRIPTION
        Parses Chrome and IE browser history. Optionally refines the results by username and/or URL.
    .PARAMETER ComputerName
        The computer name to get browsing history from. Defaults to localhost (actually... `$env:COMPUTERNAME)
        Accepts values from the pipeline.
    .PARAMETER UserName
        RegEx to match the desired username. Defaults to '.' (All characters, excluding newline)
    .PARAMETER SearchTerm
        RegEx to match the desired SearchTerm. Used to filter based on URL.
        Defaults to '.' (All characters, excluding newline)
    .PARAMETER AsJob
        Switch to use PSRemoting Jobs
    .EXAMPLE
        Get-BrowserHistory -ComputerName host1
        Gets browsing history for all users on host1.
    .EXAMPLE
        'host1','host2','host3' | Get-BrowserHistory -UserName user1 -SearchTerm evil
        Gets browsing history for user1 on host1, host2, and host3 where the URL matches 'evil'
    .INPUTS
        System.Object
        Microsoft.ActiveDirectory.Management.ADComputer
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        ###################################################################
        Author:     @oregon-national-guard/cyberspace-operations
        Version:    1.0
        ###################################################################
        License:    https://github.com/oregon-national-guard/powershell/blob/master/LICENCE
        ###################################################################
    .LINK
        https://github.com/oregon-national-guard
    .LINK
        https://creativecommons.org/publicdomain/zero/1.0/
    .LINK
        https://github.com/PowerShellMafia/PowerSploit
    .LINK
        http://www.powershellempire.com/
    .LINK
        https://github.com/EmpireProject/Empire/blob/master/data/module_source/collection/Get-BrowserData.ps1
    .LINK
        https://crucialsecurity.wordpress.com/2011/03/14/typedurls-part-1/
    .LINK
        http://forensicartifacts.com/2010/08/typedurls/
    #>

    [CmdletBinding()]
    [OutputType([psobject])]

    param (

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('PSComputerName','DNSHostName','CN','Hostname')]
        [string[]]
        $ComputerName,

        [string]
        $UserName = '.',

        [string]
        $SearchTerm = '.',

        [switch]
        $AsJob

    ) #param

    begin {

        <#
            This code currently supports parsing Chrome, IE, and FireFox history.
            Roadmap: Include Timestamps, Include Visit Count
        #>

        if (-not $ComputerName) {

            $ComputerName = $env:COMPUTERNAME

        } #if

        Write-Verbose -Message 'Start of function definitions.'

        function Get-ChromeHistory {

            [CmdletBinding()]
            [OutputType([psobject])]

            param (

                [string]
                $UserName,

                [string]
                $SearchTerm,

                [string]
                $UrlRegex = '(htt(p|ps))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?',

                [string]
                $UserExpression = '$(Split-Path -Path $(Resolve-Path -Path "$_\..\..\..\..\..\..\..") -Leaf)'

            ) #param

            begin {} #begin

            process {

                Resolve-Path -Path "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\User Data\Default\History" |

                Where-Object { $($UserExpression | Invoke-Expression) -match $UserName } |

                ForEach-Object {

                    $SourceFile = $_

                    $UserProfile = $($UserExpression | Invoke-Expression)

                    Get-Content -Path $SourceFile |

                    Select-String -Pattern $UrlRegex -AllMatches |

                    ForEach-Object { ($_.Matches).Value } |

                    Sort-Object -Unique |

                    ForEach-Object {

                        $EachUrl = $_

                        $DomainName = $EachUrl -replace 'http:\/\/','' -replace 'https:\/\/','' -replace '\/.*',''

                        New-Object -TypeName psobject -Property @{  UserName = $UserProfile
                                                                    Url = $_
                                                                    ComputerName = $env:COMPUTERNAME
                                                                    Browser = 'Chrome'
                                                                    DomainName = $DomainName }

                    } #ForEach

                } | Where-Object { $_.Url -match $SearchTerm }

            } #process

            end {} #end

        } #function Get-ChromeHistory

        function Get-InternetExplorerHistory {

            [CmdletBinding()]
            [OutputType([psobject])]

            param (

                [string]
                $UserName,

                [string]
                $SearchTerm,

                [string]
                $SidRegEx = 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$'

            ) #param

            begin {} #begin

            process {

                Get-ChildItem -Path Registry::\HKEY_USERS -ErrorAction SilentlyContinue |

                Where-Object { $_.Name -match $SidRegEx } | ForEach-Object {

                    $UserAccount = Split-Path -Path $((
                            [System.Security.Principal.SecurityIdentifier] $_.PSChildName
                        ).Translate(
                            [System.Security.Principal.NTAccount]
                        ).Value.ToString()
                    ) -Leaf

                    if ($UserAccount -match $UserName) {

                        $UserPath = $_ | Select-Object -ExpandProperty PSPath

                        $KeyPath = "$UserPath\Software\Microsoft\Internet Explorer\TypedURLs"

                        Get-Item -Path $KeyPath -ErrorAction SilentlyContinue | ForEach-Object {

                            $Key = $_

                            $Key.GetValueNames() | ForEach-Object {

                                $EachUrl = $Key.GetValue($_).Trim()

                                $DomainName = $EachUrl -replace 'http:\/\/','' -replace 'https:\/\/','' -replace '\/.*',''

                                New-Object -TypeName psobject -Property @{  UserName = $UserAccount
                                                                            Url = $EachUrl
                                                                            ComputerName = $env:COMPUTERNAME
                                                                            Browser = 'IE'
                                                                            DomainName = $DomainName } |

                                Sort-Object -Property Url -Unique |

                                Where-Object { $_.Url -match $SearchTerm }

                            } #ForEach Url

                        } #ForEach Key

                    } #if
                    
                } #ForEach RegPath

            } #process

            end {} #end

        } #function Get-InternetExplorerHistory

        function Get-FireFoxHistory {

            param (

                [string] $UserName = '.',

                [string] $SearchTerm = '.',

                [string] $UrlRegex = '(htt(p|ps))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?',

                [string]
                $UserExpression = '$(Split-Path -Path $(Resolve-Path -Path "$_\..\..\..\..\..\..") -Leaf)'

            ) #param

            begin {} #begin

            process {

                Resolve-Path -Path "$env:SystemDrive\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*.default\" |

                Where-Object { $($UserExpression | Invoke-Expression) -match $UserName } |

                ForEach-Object {

                    $EachPath = $_

                    $SourceFile = Join-Path -Path $EachPath -ChildPath 'places.sqlite'

                    $UserProfile = Split-Path -Path $(Resolve-Path -Path "$SourceFile\..\..\..\..\..\..\..") -Leaf

                    Get-Content -Path $SourceFile |

                    Select-String -Pattern $UrlRegex -AllMatches |

                    ForEach-Object { ($_.Matches).Value } |

                    Sort-Object -Unique |

                    ForEach-Object {

                        $EachUrl = $_

                        $DomainName = $EachUrl -replace 'http:\/\/','' -replace 'https:\/\/','' -replace '\/.*',''

                        New-Object -TypeName psobject -Property @{  UserName = $UserProfile
                                                                    Url = $EachUrl
                                                                    ComputerName = $env:COMPUTERNAME
                                                                    Browser = 'FireFox'
                                                                    DomainName = $DomainName }

                    } #ForEach Url

                } | Where-Object { $_.Url -match $SearchTerm }

            } #process

            end {} #end

        } #function Get-FireFoxHistory

        Write-Verbose -Message 'End of function definitions.'

        Write-Verbose -Message 'Start of function packaging.'

        $ChromeFunction = "function Get-ChromeHistory { ${function:Get-ChromeHistory} }"

        $IeFunction = "function Get-InternetExplorerHistory { ${function:Get-InternetExplorerHistory} }"

        $FireFoxFunction = "function Get-FireFoxHistory { ${function:Get-FireFoxHistory} }"

        Write-Verbose -Message 'End of function packaging.'

    } #begin

    process {

        $ComputerName | ForEach-Object {

            $EachComputer = $_

            Write-Verbose -Message "Starting execution on '$EachComputer'"
            Write-Verbose -Message 'Checking for -AsJob switch parameter.'

            if ($AsJob) {

                Write-Verbose -Message 'Running asynchronously due to -AsJob switch parameter.'
                Write-Verbose -Message "Check to see if we're running locally."

                if ($EachComputer -match $env:COMPUTERNAME) {

                    Write-Verbose -Message "We're running locally."
                    Write-Verbose -Message 'Starting local job.'

                    Start-Job -ScriptBlock {

                        Get-ChromeHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-InternetExplorerHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-FireFoxHistory -UserName $UserName -SearchTerm $SearchTerm

                    } # Local Job

                    Write-Verbose -Message 'Use "Get-Job" to see if it was successful or not.'

                } else {

                    Write-Verbose -Message "We're running remotely."
                    Write-Verbose -Message 'Using Invoke-Command -AsJob to start remote job.'

                    Invoke-Command -ComputerName $EachComputer -ScriptBlock {

                        param (

                            $UserName,
                            $SearchTerm,
                            $ChromeFunction,
                            $IeFunction,
                            $FireFoxFunction

                        ) #param

                        . ([ScriptBlock]::Create($ChromeFunction))

                        . ([ScriptBlock]::Create($IeFunction))

                        . ([ScriptBlock]::Create($FireFoxFunction))

                        Get-ChromeHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-InternetExplorerHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-FireFoxHistory -UserName $UserName -SearchTerm $SearchTerm

                    } -ArgumentList $UserName,$SearchTerm,$ChromeFunction,$IeFunction,$FireFoxFunction -AsJob

                    Write-Verbose -Message 'Remote job created.'
                    Write-Verbose -Message 'Use "Get-Job" to see if it was successful or not.'

                } #if ($EachComputer -match $env:COMPUTERNAME)

            } else {

                Write-Verbose -Message 'Running synchronously due to lack of -AsJob switch parameter.'
                Write-Verbose -Message "Check to see if we're running locally."

                if ($EachComputer -match $env:COMPUTERNAME) {

                    Write-Verbose -Message "We're running locally."

                    Get-ChromeHistory -UserName $UserName -SearchTerm $SearchTerm |
                        Select-Object -Property ComputerName,UserName,Browser,DomainName,Url

                    Get-InternetExplorerHistory -UserName $UserName -SearchTerm $SearchTerm |
                        Select-Object -Property ComputerName,UserName,Browser,DomainName,Url

                    Get-FireFoxHistory -UserName $UserName -SearchTerm $SearchTerm |
                        Select-Object -Property ComputerName,UserName,Browser,DomainName,Url

                } else {

                    Write-Verbose -Message "We're running remotely."
                    Write-Verbose -Message 'Using Invoke-Command -AsJob to start remote job.'

                    Invoke-Command -ComputerName $EachComputer -ScriptBlock {

                        param (

                            $UserName,
                            $SearchTerm,
                            $ChromeFunction,
                            $IeFunction,
                            $FireFoxFunction

                        ) #param

                        . ([ScriptBlock]::Create($ChromeFunction))

                        . ([ScriptBlock]::Create($IeFunction))

                        . ([ScriptBlock]::Create($FireFoxFunction))

                        Get-ChromeHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-InternetExplorerHistory -UserName $UserName -SearchTerm $SearchTerm

                        Get-FireFoxHistory -UserName $UserName -SearchTerm $SearchTerm

                    } -ArgumentList $UserName,$SearchTerm,$ChromeFunction,$IeFunction,$FireFoxFunction |

                    Select-Object -Property ComputerName,UserName,Browser,DomainName,Url

                } #if ($EachComputer -match $env:COMPUTERNAME)

            } #if ($AsJob)

        } #ForEach $ComputerName

    } #process

    end {} #end

} #function Get-BrowserHistory
