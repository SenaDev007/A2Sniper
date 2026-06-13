# Correction des erreurs de compilation

# 1. Correction PatternDetector.mqh
$patternFile = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternFile -Raw

# Corrections des signatures de méthodes
$content = $content -replace 'void AddPatternToHistory\(SPatternInfo pattern\);', 'void AddPatternToHistory(const SPatternInfo& pattern);'
$content = $content -replace 'void PrintPatternInfo\(SPatternInfo pattern\);', 'void PrintPatternInfo(const SPatternInfo& pattern);'

# Correction du tableau
$content = $content -replace 'SPatternInfo\s+m_pattern_history\[\];', 'SPatternInfo m_pattern_history[100];'
$content = $content -replace 'ArrayInitialize\(m_pattern_history, 0\);', '// Tableau initialisé automatiquement'

$content | Set-Content -Path $patternFile -Encoding UTF8

# 2. Correction A2SniperTrading.mq5
$a2SniperFile = "A2SniperTrading.mq5"
$content = Get-Content -Path $a2SniperFile -Raw

# Corrections des appels de méthodes
$content = $content -replace 'ha_calculator->Update\(\);', 'ha_calculator.Update();'
$content = $content -replace 'pattern_detector->DetectBuyPattern\(ha_calculator,', 'pattern_detector.DetectBuyPattern(&ha_calculator,'
$content = $content -replace 'pattern_detector->DetectSellPattern\(ha_calculator,', 'pattern_detector.DetectSellPattern(&ha_calculator,'

$content | Set-Content -Path $a2SniperFile -Encoding UTF8

Write-Host "Corrections appliquées avec succès!"
