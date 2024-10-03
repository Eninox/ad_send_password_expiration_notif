
# --------------------------------------------------------------------------------------- #
# Reporting des comptes users actifs avec un mot de passe AD qui expire à X jours, 		  #
# avec notification par mail.                                                             #
# --------------------------------------------------------------------------------------- #

Import-Module ActiveDirectory

# Cible l'OU comprenant tous les users actifs 
$TargetOU = "OU=XXXXX,DC=domaine"
# Nombre de jours à reporter (X)
$NumberOfDays = 9
# Date du jour, seuil de comparaison 
$Date = Get-Date
# Date future = date du jour + le nombre de jours à reporter
$DateFuture = $Date.AddDays($NumberOfDays)
# Tableau cible, vide qui sera alimenté avec les users à reporter
$UsersPwdToChange = @()
# Compteur vide qui sera alimenté avec les users à reporter
$CountUsers = 0

# Requête AD qui récupère l'ensemble des comptes users actifs de l'OU ciblée avec date expiration mot de passe, tri par date d'expiration
$UsersInfo = Get-ADUser -Filter { (Enabled -eq $True) -and (PasswordNeverExpires -eq $False)} -SearchBase $TargetOU –Properties "Samaccountname", "DisplayName", "mail", "msDS-UserPasswordExpiryTimeComputed" | 
           Select-Object -Property "Samaccountname","Displayname","mail",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | Sort-Object -Property "ExpiryDate"

# Composition du tableau cible qui comprend les users ayant un mot de passe AD qui expire à X jours
foreach ($User in $UsersInfo) {
    if ($User.ExpiryDate -lt $DateFuture -and $User.ExpiryDate -gt $Date) {
        $CountUsers += 1
        $UsersPwdToChange += $User
    }
}

# Ajout de l'objet DateOnly au tableau cible, pour permettre de comptabiliser les users par date
$UsersPwdToChange | ForEach-Object { 
    $_ | Add-Member -MemberType NoteProperty -Name 'DateOnly' -Value ($_.ExpiryDate).ToString("dd/MM/yyyy")
}

# Création variable technique qui comptabilise le nombre de users par date expiration
$UsersGroupByDateOnly = $UsersPwdToChange | Group-Object -Property DateOnly | Select-Object Name, @{Name="NbUsers";Expression={$_.Count}} 

# Création variable technique pour corps du mail envoyé
$MailContent = @"
    <html>
        <head></head>
        <body style='font-family:Calibri;'>
            Bonjour,
            <br> 
            <p>Voici la liste des $CountUsers comptes Active Directory dont le mot de passe expire à $NumberOfDays jours.</p>
            <ul>
"@

# Alimentation du corps du mail avec les éléments de nombre users par date expiration
foreach ($User in $UsersGroupByDateOnly) {
    $MailContent += "<li>" + $User.Name + " -> " + $User.NbUsers + "</li>"
}

# Création variable technique pour convertir le tableau de données cible au format html
$UsersToSend = $UsersPwdToChange | Sort-Object -Property "ExpiryDate" | ConvertTo-HTML -Property SamAccountName,DisplayName,mail,ExpiryDate | `
    Out-String | ForEach-Object {
        $_  -replace "<table>","<table style='border: 1px solid;font-family:Calibri;'>" `
            -replace "<th>","<th style='border: 1px solid; padding: 5px; background-color:#014B83; color:#fff;'>" `
            -replace "<td>","<td style='padding: 10px;'>"
        }

# Alimentation du corps du mail avec les éléments html précédemment convertis
$MailContent += $UsersToSend

# Envoi du mail aux destinataires cible, corps du mail composé des 3 parties précédemment saisies
Send-MailMessage `
	-Encoding UTF8 `
    -From 'AD_PasswordExpiration AD_PasswordExpiration@domain-mail' `
    -To 'destinataire1@domain-mail','destinataire2@domain-mail' `
    -Cc 'destinataire3@domain-mail' `
    -Subject "Synthèse - Expiration des mots de passe AD à $NumberOfDays jours" `
    -BodyAsHtml `
    -Body $MailContent `
    -SmtpServer 'serverX'
