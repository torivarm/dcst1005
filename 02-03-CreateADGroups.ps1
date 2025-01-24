# Define your groups with their properties
$groups = @(
    @{
        Name = "g_all_hr"
        Path = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "g_all_it"
        Path = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "g_all_sales"
        Path = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "g_all_finance"
        Path = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "g_all_consultants"
        Path = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    }
)

# Create each group
foreach ($group in $groups) {
    New-ADGroup -Name $group.Name `
        -GroupScope $group.Scope `
        -GroupCategory $group.Category `
        -Path $group.Path
}