$patternDetectorPath = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternDetectorPath -Raw

# Modification de la condition de volume pour l'assouplir à 0.7 fois la moyenne
$volumeConditionRegex = 'bool result = \(volume_buffer\[doji_index\] >= [0-9\.]+? \* avg_volume\);'
$volumeConditionReplacement = 'bool result = (volume_buffer[doji_index] >= 0.7 * avg_volume);'
$content = $content -replace $volumeConditionRegex, $volumeConditionReplacement

# Mise à jour du message de log pour refléter le nouveau seuil
$volumeLogRegex = 'Print\("\[PATTERN DETECTOR\] Seuil minimum renforcÃ©: [0-9\.]+? \* volume moyen = ", avg_volume\);'
$volumeLogReplacement = 'Print("[PATTERN DETECTOR] Seuil minimum équilibré: 0.7 * volume moyen = ", 0.7 * avg_volume);'
$content = $content -replace $volumeLogRegex, $volumeLogReplacement

# Sauvegarde du fichier modifié
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8

Write-Host "Condition de volume assouplie avec succès dans le fichier $patternDetectorPath"
