$patternDetectorPath = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternDetectorPath -Raw

# Correction des références aux méthodes de CIntelligentPatternDetector
# qui doivent être appelées sur l'instance m_intelligent_detector

# Correction des appels dans les méthodes de validation intelligente
$content = $content -replace 'CIntelligentPatternDetector::', 'CPatternDetector::'

# Correction des appels aux méthodes de validation dans les méthodes principales
$validationMethods = @(
    'ValidateMultiTimeframeAlignment',
    'ValidateMomentumConfirmation', 
    'ValidateSupportResistanceLevel',
    'ValidateVolumeSurge',
    'ValidateMarketStructure',
    'ValidateVolatilityFilter',
    'ValidatePriceActionConfirmation',
    'CalculateIntelligentConfidenceScore'
)

foreach ($method in $validationMethods) {
    # Remplacer les appels directs par des appels via l'instance
    $content = $content -replace "(\s+)$method\(", "`$1this.$method("
}

# Correction spécifique pour les méthodes DetectHighProbability*
$content = $content -replace 'DetectHighProbabilityBuyPattern', 'DetectBuyPattern'
$content = $content -replace 'DetectHighProbabilitySellPattern', 'DetectSellPattern'

# Sauvegarde du fichier corrigé
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8

Write-Host "Corrections finales appliquées au fichier PatternDetector.mqh"
Write-Host "Le système devrait maintenant compiler correctement."
