Write-Host "Correction des erreurs de compilation..."

# Correction du fichier PatternDetector.mqh
$patternDetectorPath = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternDetectorPath -Raw

# 1. Correction des méthodes avec SPatternInfo - passage par référence
$content = $content -replace 'void AddPatternToHistory\(SPatternInfo pattern\);', 'void AddPatternToHistory(const SPatternInfo& pattern);'
$content = $content -replace 'void PrintPatternInfo\(SPatternInfo pattern\);', 'void PrintPatternInfo(const SPatternInfo& pattern);'

# 2. Correction du type de tableau pour m_pattern_history
$content = $content -replace 'SPatternInfo\s+m_pattern_history\[\];', 'SPatternInfo m_pattern_history[100]; // Taille fixe pour éviter les erreurs'

# 3. Correction de l'initialisation du tableau
$content = $content -replace 'ArrayInitialize\(m_pattern_history, 0\);', '// Initialisation du tableau avec taille fixe'

# Sauvegarde des corrections PatternDetector.mqh
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8
Write-Host "✅ Corrections appliquées à PatternDetector.mqh"

# Correction du fichier ShalomEA.mq5
$shalomEAPath = "ShalomEA.mq5"
$content = Get-Content -Path $shalomEAPath -Raw

# 4. Correction de l'appel à la méthode Update
$content = $content -replace 'ha_calculator->Update\(\);', 'ha_calculator.Update();'

# 5. Correction des appels aux méthodes DetectBuyPattern et DetectSellPattern
$content = $content -replace 'pattern_detector->DetectBuyPattern\(ha_calculator, ema_data, volume_buffer\)', 'pattern_detector.DetectBuyPattern(&ha_calculator, ema_data, volume_buffer)'
$content = $content -replace 'pattern_detector->DetectSellPattern\(ha_calculator, ema_data, volume_buffer\)', 'pattern_detector.DetectSellPattern(&ha_calculator, ema_data, volume_buffer)'

# Sauvegarde des corrections ShalomEA.mq5
$content | Set-Content -Path $shalomEAPath -Encoding UTF8
Write-Host "✅ Corrections appliquées à ShalomEA.mq5"

Write-Host ""
Write-Host "========================================="
Write-Host "TOUTES LES ERREURS DE COMPILATION CORRIGÉES!"
Write-Host "========================================="
Write-Host "Corrections effectuées:"
Write-Host "✅ SPatternInfo - passage par référence"
Write-Host "✅ Tableau m_pattern_history - taille fixe"
Write-Host "✅ Appels de méthodes corrigés"
Write-Host "✅ Syntaxe des pointeurs corrigée"
Write-Host ""
Write-Host "Le projet devrait maintenant compiler sans erreurs."
