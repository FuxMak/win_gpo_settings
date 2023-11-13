#!powershell

# Copyright: (c) 2023, Marco Fuchs <mfuchs135@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module GroupPolicy

$ErrorActionPreference = "Stop"

# --- Helper functions ---

function Get-GPRegistryValueWrapper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ValueName,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $params = @{
        ValueName = $ValueName
        Name      = $Name
        Key       = $Key
    }

    try {
        Get-GPRegistryValue @params
    }
    catch {
        return $null
    }

    return Get-GPRegistryValue @params
}
function Set-GPRegistryValueWrapper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ValueName,
        [Parameter(Mandatory = $true)]
        $Value,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $params = @{
        ValueName = $ValueName
        Value     = $Value
        Name      = $Name
        Key       = $Key
        Type      = $Type
    }

    try {
        Set-GPRegistryValue @params | Out-Null
    }
    catch {
        $module.FailJson("Failed to set group policy registry value: $($_.Exception.Message)")
    }


}
function Remove-GPRegistryValueWrapper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $false)]
        [string]$ValueName
    )
    $params = @{
        Name      = $Name
        Key       = $Key
        ValueName = $ValueName
    }

    try {
        $gpo_setting = Remove-GPRegistryValue @params
        return $gpo_setting
    }
    catch {
        $module.FailJson("Failed to remove group policy registry value: $($_.Exception.Message)")
    }
}
function Disable-GPRegistryValueWrapper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $false)]
        [string]$ValueName
    )

    $params = @{
        Name      = $Name
        Key       = $Key
        ValueName = $ValueName
        Disable   = $true
    }

    try {
        Set-GPRegistryValue @params | Out-Null
    }
    catch {
        $module.FailJson("Failed to disable group policy registry value: $($_.Exception.Message)")
    }
}

# --- Initialize Ansible module ---

$spec = @{
    options             = @{
        gpo_value      = @{ type = 'str' }
        gpo_value_name = @{ type = 'str' }
        gpo_name       = @{ type = 'str' }
        key_path       = @{ type = 'str' }
        key_type       = @{
            type    = "str"
            choices = "String", "ExpandString", "Binary", "DWord", "MultiString", "QWord"
        }
        state          = @{
            type    = "str"
            default = "present"
            choices = "present", "absent", "disabled"
        }
        # auto_create_gpo = @{ type = 'bool'; default = $true }
    }
    required_if         = @(
        @("state", "present", @("key_path", "gpo_name", "key_type", "gpo_value")),
        @("state", "absent", @("key_path", "gpo_name")),
        @("state", "disabled", @("key_path", "gpo_name"))
    )
    # TODO: Implement check mode
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$gpo_value_name = $module.Params.gpo_value_name
$gpo_value = $module.Params.gpo_value
$gpo_name = $module.Params.gpo_name
$key_path = $module.Params.key_path
$key_type = $module.Params.key_type
# $auto_create_gpo = $module.Params.auto_create_gpo
$state = $module.Params.state


# --- Sanity checks and fact gathering ---

# Check that registry key is in correct format: HKCU or HKLM
if ($key_path -notmatch "^HKEY_(CURRENT_USER|LOCAL_MACHINE)\\") {
    $module.FailJson("$key_path is not a valid registry key path, see module documentation for examples.")
}

# Check if requested group policy object exists -> Create if required
try {
    Get-GPO -Name $gpo_name -ErrorAction Stop | Out-Null
}
catch [System.ArgumentException] {
    Write-Verbose "Unable to find group policy object with name: $gpo_name..."
    New-GPO -Name $gpo_name | Out-Null
}
catch {
    $module.FailJson("An unexpected error occurred: $_")
}

# try {
#     Get-GPO -Name $gpo_name | Out-Null
# }
# catch {
#     # Create GPO if it doesn't exist
#     if ($auto_create_gpo -eq $false) {
#         $module.FailJson("Unable to find group policy object with name: $gpo_name...")
#     }
#     New-GPO -Name $gpo_name | Out-Null
# }

# Check for type and convert if necessary
if (($key_type -eq "DWord") -or ($key_type -eq "QWord")) { $gpo_value = [int]$gpo_value }

# Check if settings are present under that registry key path
$gpo_prev_state = $null
$gpo_prev_value = Get-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -ValueName $gpo_value_name

if ($null -ne $gpo_prev_value) {
    $gpo_prev_state = Get-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -ValueName $gpo_value_name | Select-Object -ExpandProperty PolicyState
    $gpo_prev_value = Get-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -ValueName $gpo_value_name | Select-Object -ExpandProperty Value
}


# Check if settings are already present
if (($gpo_prev_value -eq $gpo_value) -and ($state -eq "present")) {
    $module.ExitJson()
}

# Check if policy is already disabled
if (($gpo_prev_state -eq "Delete") -and ($state -eq "disabled")) {
    $module.ExitJson()
}

# Check if key or value needs to be removed
if ($state -eq "absent") {

    # Check if value is empty, but would be removed anyway
    if ($null -eq $gpo_prev_value) {
        $module.ExitJson()
    }

    # Check if all settings related to key should be removed
    if ($null -eq $gpo_value_name) {
        try {
            Remove-GPRegistryValueWrapper -Name $gpo_name -Key $key_path
        }
        catch {
            $module.FailJson("Failed to remove group policy settings related to specified registry key: $($_.Exception.Message)")
        }
    }

    try {
        Remove-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -ValueName $gpo_value_name
    }
    catch {
        $module.FailJson("Failed to remove group policy registry value: $($_.Exception.Message)")
    }

    $module.Result.changed = $true
    $module.ExitJson()
}

# Check if value needs to be disabled
if (($gpo_prev_value -eq $gpo_value) -and ($state -eq "disabled")) {
    try {
        Disable-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -ValueName $gpo_value_name
        $module.Result.changed = $true
        $module.ExitJson()
    }
    catch {
        $module.FailJson("Failed to disable group policy registry value: $($_.Exception.Message)")
    }
}

# All pre-checks passed -> set value
try {
    Set-GPRegistryValueWrapper -Name $gpo_name -Key $key_path -Value $gpo_value -ValueName $gpo_value_name -Type $key_type
    $module.Result.changed = $true
}
catch {
    $module.FailJson("Failed to set group policy registry value: $($_.Exception.Message)")
}

$module.ExitJson()
