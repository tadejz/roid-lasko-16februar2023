Import-Module ActiveDirectory

# VARIABLES
$SCOPE = "" # Define OU, containing users we want to manage
$GROUPNAMEPREFIX = "" # Add group naming prefix, e.g. "Students from {department}"
$GROUPNAMESUFFIX = "" # Add group naming suffix, e.g. "{department} students"

# POPULATE LIST OF DEPARTMENTS

[string[]] $GroupList = Get-AdUser -Filter * -Properties Department -SearchBase $scopeOU -SearchScope OneLevel | Select-Object -ExpandProperty Department -Unique

# MAIN LOOP
Foreach ($Group In $GroupList)
{
	# Set temporary variables
    $users = @()
    $removeMember = @()
    $addMember = @()
	
	# Build search string for current department group
	$searchString = $GROUPNAMEPREFIX + $Group + $GROUPNAMESUFFIX
    
    # Get the current members of current department group
    $ADGroup = Get-ADGroup -Filter "name -eq '$searchString'" -Properties Members,Name
    
    # Get the list of users with the department name
    $DeptFilter = "Department -eq '$Group'"
    $Users = @(Get-AdUser -Filter $DeptFilter -Properties Department -SearchBase $scopeOU -SearchScope OneLevel)
    
    # Remove users who are no longer in the department
    $removeMember = @($ADGroup.Members | Where-Object {$PSItem -notin $Users.DistinguishedName} )

    if ($removeMember)
    {
        Remove-ADGroupMember -Identity $ADGroup.DistinguishedName -Members $removeMember -Confirm:$false -Verbose
    }

    # Add new users to the department
    $addMember = $Users | Where-Object {$PSItem.Distinguishedname -notin $ADGroup.Members}
    
    if ($addMember)
    {
        Add-ADGroupMember -Identity $ADGroup.DistinguishedName -Members $addMember -Verbose
    }
}