## One line scripts

### Locate enabled and locked users
```
Get-ADUser -Filter '*' -Properties * | ?{$_.LockedOut -And $_.Enabled} | Sort-Object WhenChanged -Descending | Select -Property Name, DisplayName, WhenChanged
```
