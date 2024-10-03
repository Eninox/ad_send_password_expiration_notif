# ad_send_password_expiration_notif
Script de reporting des users AD actifs avec mot de passe qui expire à X jours et notification par mail (équipe technique)

1. Définition de l'OU cible, du nombre de jours à analyser
2. Collecte des informations AD user
3. Composition tableau avec seulement les users qui ont un mot de passe expirant dans la période cible
4. Composition et envoi du mail de notification avec :
* Nb total users
* Nb users par date
* Tableau de données complet

Script inspiré et adapté depuis it-connect https://github.com/it-connect-fr/PowerShell-ActiveDirectory/tree/main
