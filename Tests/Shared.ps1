#Requires -Modules Pester

# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleName = 'JiraPS'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleName.psd1"
$RootModule = "$PSScriptRoot\..\$ModuleName\$ModuleName.psm1"

# The first time this is called, the module will be forcibly (re-)imported.
# After importing it once, the $SuppressImportModule flag should prevent
# the module from being imported again for each test file.

if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) -or (-not $SuppressImportModule)) {
    # If we import the .psd1 file, Pester has issues where it detects multiple
    # modules named JiraPS. Importing the .psm1 file seems to correct this.

    # -Scope Global is needed when running tests from within a CI environment
    Import-Module $RootModule -Scope Global -Force

    # Set to true so we don't need to import it again for the next test
    $script:SuppressImportModule = $true
}

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'ShowMockData')]
$script:ShowMockData = $false

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'ShowDebugText')]
$script:ShowDebugText = $false

function defProp($obj, $propName, $propValue) {
    It "Defines the '$propName' property" {
        $obj.$propName | Should Be $propValue
    }
}

function hasProp($obj, $propName) {
    It "Defines the '$propName' property" {
        $obj | Get-Member -MemberType *Property -Name $propName | Should Not BeNullOrEmpty
    }
}

function hasNotProp($obj, $propName) {
    It "Defines the '$propName' property" {
        $obj | Get-Member -MemberType *Property -Name $propName | Should BeNullOrEmpty
    }
}

function defParam($command, $name) {
    It "Has a -$name parameter" {
        $command.Parameters.Item($name) | Should Not BeNullOrEmpty
    }
}

function defAlias($name, $definition) {
    It "Supports the $name alias for the $definition parameter" {
        $command.Parameters.Item($definition).Aliases | Where-Object -FilterScript {$_ -eq $name} | Should Not BeNullOrEmpty
    }
}

# This function must be used from within an It block
function checkType($obj, $typeName) {
    if ($obj -is [System.Array]) {
        $o = $obj[0]
    }
    else {
        $o = $obj
    }

    (Get-Member -InputObject $o).TypeName -contains $typeName | Should Be $true
}

function castsToString($obj) {
    if ($obj -is [System.Array]) {
        $o = $obj[0]
    }
    else {
        $o = $obj
    }

    $o.ToString() | Should Not BeNullOrEmpty
}

function checkPsType($obj, $typeName) {
    It "Uses output type of '$typeName'" {
        checkType $obj $typeName
    }
    It "Can cast to string" {
        castsToString($obj)
    }
}

function ShowMockInfo {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
    param(
        $functionName,
        [String[]] $params
    )
    if ($script:ShowMockData) { #TODO
        Write-Host "       Mocked $functionName" -ForegroundColor Cyan
        foreach ($p in $params) {
            Write-Host "         [$p]  $(Get-Variable -Name $p -ValueOnly -ErrorAction SilentlyContinue)" -ForegroundColor Cyan
        }
    }
}

Mock "Write-Debug" {
    MockedDebug $Message
}

function MockedDebug {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    param(
        $Message
    )
    if ($ShowDebugText) {
        Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
    }
}
