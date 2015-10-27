
Function Get-Manager
    {
        <#
        .SYNOPSIS 
            Get-Manager will return two levels of management for the inputed user(s), as defined in Active Directory.

        .DESCRIPTION
            Get-Manager will return two levels of management for the inputed user(s), as defined in Active Directory.
            The ActiveDirectory PowerShell module is required for this function to run correctly.

        .PARAMETER Names
            An array of strings.  To avoid finding more than one user per name, this should be a specific Active Directory username.
            
            If the specific Active Directory username is unknown, the Get-Name function can be used to get it.

        .INPUTS
            The Names parameter will accept pipeline input in the form of an array of strings.

        .OUTPUTS
            The Get-Manager function outputs a custom object with 10 properties for each name in the array, as defined below.

            Default Property Set of Object includes:
            User:  User information in the form of:   UserDisplayName (UserName)
            Manager:  Manager information in the form of:   ManagerDisplayName (ManagerName)
            Director:  Director information in the form of:   DirectorDisplayName (DirectorName)
            Enabled:  Shows whether the Active Directory user account is enabled or not.

            Other Propteries:
            UserName:  This is the Active Directory name of the user.
            UserDisplayName:  This is the Active Directory display name of the user.
            ManagerName:  This is the Active Directory name of the user's manager.
            ManagerDisplayName:  This is the Active Directory display name of the user's manager.
            DirectorName:  This is the Active Directory name of the user director.
            DirectorDisplayName:  This is the Active Directory display name of the user's director.
            

        .EXAMPLE
            PS E:\Scripts\PowerShell> get-manager jdoe

            User                 Manager               Director             Enabled
            ----                 -------               --------             -------
            John Doe (jdoe)      Mary Jane (mjane)     Joe Smith (jsmith)   True
        #>

        [CmdletBinding()]
        Param([parameter(Mandatory=$True,ValueFromPipeline=$True)] [string[]]$Names)

        Process
            {
                $Results = @()
                ForEach ( $Name in $Names )
                    {
                        $Object = New-Object psobject 
                        
                        Try
                            {
                                $User = get-aduser $Name -Properties Displayname, manager
                                $Manager = get-aduser $user.Manager -Properties Displayname, manager
                                $Director = get-aduser $Manager.Manager -Properties Displayname, manager
                            }
                        Catch
                            {
                                If ( $user -eq $null )
                                    {
                                        $user = New-Object psobject -Property @{Name=$Name;DisplayName='Not Found';Enabled=$False}
                                        $Manager = New-Object psobject -Property @{Name='Not Found';DisplayName='Not Found'}
                                        $Director = New-Object psobject -Property @{Name='Not Found';DisplayName='Not Found'}
                                    }
                                ElseIf ($manager -eq $null  )
                                    {
                                        $Manager = New-Object psobject -Property @{Name=$user.Manager;DisplayName='Not Found'}
                                        $Director = New-Object psobject -Property @{Name='Not Found';DisplayName='Not Found'}
                                    }
                                ElseIf ( $Director -eq $null )
                                    {
                                        $Director = New-Object psobject -Property @{Name=$Manager.Manager;DisplayName='Not Found'}
                                    }
                            }
                        
                        $Object | add-member -name User -MemberType NoteProperty -Value "$($User.displayname) ($($User.Name))"
                        $Object | add-member -name UserName -MemberType NoteProperty -Value $user.Name
                        $Object | add-member -name UserDisplayName -MemberType NoteProperty -Value $user.DisplayName
                        $Object | add-member -name ManagerName -MemberType NoteProperty -Value $Manager.Name
                        $Object | add-member -name ManagerDisplayName -MemberType NoteProperty -Value $Manager.DisplayName
                        $Object | add-member -name Manager -MemberType NoteProperty -Value "$($Manager.displayname) ($($Object.ManagerName))"
                        $Object | add-member -name DirectorName -MemberType NoteProperty -Value  $Director.Name
                        $Object | add-member -name DirectorDisplayName -MemberType NoteProperty -Value  $Director.DisplayName
                        $Object | add-member -name Director -MemberType NoteProperty -Value "$($Director.displayname) ($($Object.DirectorName))"
                        $Object | add-member -name Enabled -MemberType NoteProperty -Value $User.Enabled
                        
                        $defaultProperties = @(‘User’,’Manager',’Director','Enabled')
                        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
                        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                        $Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers
                        Remove-Variable user, Manager, Director
                        $Results += $object
                        
                    } 
                $Results               
            }
    }


Function Get-Name
    {
        <#
        .SYNOPSIS 
            Get-Name will query Active Directory and return name information.

        .DESCRIPTION
            Get-Name will accept an array of strings, in the form of Active Directory Usernames, Display Names or Distinguised Names, and will return
            the Display Name, Name and Title of the user in AD.

        .PARAMETER Names
            An array of strings.  This should be either Active Directory Usernames, Display Names or Distinguised Names.

        .INPUTS
            The Names parameter will accept pipeline input in the form of an array of strings.

        .OUTPUTS
            The Get-Name function outputs a custom object with 3 properties for each name in the array, as defined below.

            DisplayName:  Account Display Name in Active Directory.
            Name:  Account Name in Active Directory.
            Title:  Account Title in Active Directory.
            
        .EXAMPLE
            PS E:\Scripts\PowerShell> get-Name 'john doe'

            DisplayName Name    Title
            ----------- ----    -----
            John Doe    jdoe    Manager

        .EXAMPLE
            PS E:\Scripts\PowerShell> get-Name 'jdoe'

            DisplayName Name    Title
            ----------- ----    -----
            John Doe    jdoe    Manager

        .EXAMPLE
            PS E:\Scripts\PowerShell> get-Name 'CN=jdoe,OU=Users,OU=Domain,DC=com'

            DisplayName Name    Title
            ----------- ----    -----
            John Doe    jdoe    Manager
        #>
        
        [CmdletBinding()]
        Param([parameter(Mandatory=$True,ValueFromPipeline=$True)] [string[]]$Names)

        Process
            {
                $Results = @()
                ForEach ( $Name in $Names )
                    {
                        $Users = get-aduser -filter "name -like '$name' -or displayname -like '$name' -or DistinguishedName -like '$name'" -Properties Displayname, Title
                            
                            ForEach ( $User in $Users )
                                {
                                    $Object = New-Object psobject
                                    $Object | Add-Member -Name DisplayName -MemberType NoteProperty -Value $User.DisplayName
                                    $Object | Add-Member -Name Name -MemberType NoteProperty -Value $User.Name
                                    $Object | Add-Member -Name Title -MemberType NoteProperty -Value $User.Title

                                    $Results += $Object
                                    Remove-Variable Object
                                } 
                    }
                $Results
            }
    }


function Get-ADDirectReports
{
	<#
	.SYNOPSIS
		This function retrieve the directreports property from the IdentitySpecified.
		Optionally you can specify the Recurse parameter to find all the indirect
		users reporting to the specify account (Identity).
	
	.DESCRIPTION
		This function retrieve the directreports property from the IdentitySpecified.
		Optionally you can specify the Recurse parameter to find all the indirect
		users reporting to the specify account (Identity).
	
	.NOTES
		Francois-Xavier Cat
		www.lazywinadmin.com
		@lazywinadm
	
		Blog post: http://www.lazywinadmin.com/2014/10/powershell-who-reports-to-whom-active.html
	
		VERSION HISTORY
		1.0 2014/10/05 Initial Version
	
	.PARAMETER Identity
		Specify the account to inspect
	
	.PARAMETER Recurse
		Specify that you want to retrieve all the indirect users under the account
	
	.EXAMPLE
		Get-ADDirectReports -Identity Test_director
	
Name                SamAccountName      Mail                Manager
----                --------------      ----                -------
test_managerB       test_managerB       test_managerB@la... test_director
test_managerA       test_managerA       test_managerA@la... test_director
		
	.EXAMPLE
		Get-ADDirectReports -Identity Test_director -Recurse
	
Name                SamAccountName      Mail                Manager
----                --------------      ----                -------
test_managerB       test_managerB       test_managerB@la... test_director
test_userB1         test_userB1         test_userB1@lazy... test_managerB
test_userB2         test_userB2         test_userB2@lazy... test_managerB
test_managerA       test_managerA       test_managerA@la... test_director
test_userA2         test_userA2         test_userA2@lazy... test_managerA
test_userA1         test_userA1         test_userA1@lazy... test_managerA
	
	#>
	[CmdletBinding()]
	PARAM (
		[Parameter(Mandatory)]
		[String[]]$Identity,
		[Switch]$Recurse
	)

	PROCESS
	{
		foreach ($Account in $Identity)
		{
			TRY
			{
				IF ($PSBoundParameters['Recurse'])
				{
					# Get the DirectReports
					Write-Verbose -Message "[PROCESS] Account: $Account (Recursive)"
					Get-Aduser -identity $Account -Properties directreports |
					ForEach-Object -Process {
						$_.directreports | ForEach-Object -Process {
							# Output the current object with the properties Name, SamAccountName, Mail and Manager
							Get-ADUser -Identity $PSItem -Properties * | Select-Object -Property *, @{ Name = "ManagerAccount"; Expression = { (Get-Aduser -identity $psitem.manager).samaccountname } }
							# Gather DirectReports under the current object and so on...
							Get-ADDirectReports -Identity $PSItem -Recurse
						}
					}
				}#IF($PSBoundParameters['Recurse'])

			}#TRY
			CATCH
			{
				Write-Verbose -Message "[PROCESS] Something wrong happened"
				Write-Verbose -Message $Error[0].Exception.Message
			}
		}
	}

}

Function Get-Pyramid
    {
        <#
        .SYNOPSIS 
            Get-Pyramid returns all personnel that reports to the input user.

        .DESCRIPTION
            Get-Pyramid uses Get-ADDirectReports function by Francois-Xavier Cat to retrieve all personnel that reports
            to one person, and sends each user through the Get Manager function, then returns all of them sorted by Director, manager then user.

        .PARAMETER Name
            The AD name that will be used to find all reports.

        .INPUTS
            A single string, should be an Active Directory User Name.  Should be input either by parameter or by pipeline.

        .OUTPUTS
            All direct and indirect reports of the input user are retrieved and sent through Get-Manager function.

        .EXAMPLE
            PS E:\Scripts\PowerShell> get-pyramid jdoe

            User                      Manager               Director             Enabled
            ----                      -------               --------             -------
            John Snow (jsnow)         John Doe (jdoe)       Mary Jane (mjane)    True
            Arya Stark (astark)       John Doe (jdoe)       Mary Jane (mjane)    True
        #>
        
        [CmdletBinding()]
        Param([parameter(Mandatory=$True,ValueFromPipeline=$True)] [string]$Name)

        Process
            {
                $Users = (Get-ADDirectReports -Identity $Name -Recurse).Name
                If ($Users.count -gt 0)
                    {
                        $Users | get-manager | sort -Property Director, Manager, User

                        Write-Output ""
                        Write-Output "Total Count: $($Users.Count)"
                    }
                Else
                    {
                        Write-Output "No direct reports found."
                    }
            }
    }


New-Alias gmgr Get-Manager
New-Alias gn Get-Name
New-Alias gpyr Get-Pyramid

Export-ModuleMember -Function Get-Manager, Get-Name, Get-Pyramid -Alias gmgr, gn, gpyr
