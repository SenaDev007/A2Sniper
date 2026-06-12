$patternDetectorPath = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternDetectorPath -Raw

# Suppression des références incorrectes aux méthodes CIntelligentPatternDetector
$content = $content -replace 'CIntelligentPatternDetector::', 'CPatternDetector::'

# Correction des appels aux méthodes de validation qui n'existent pas
$invalidMethods = @(
    'ValidateStrongTrendDirection',
    'ValidateAdvancedPullback', 
    'ValidateStrongDojiConfirmation',
    'ValidateAdvancedVolumeCondition',
    'ValidateStrongMarketStructure',
    'ValidateOptimalTiming'
)

foreach ($method in $invalidMethods) {
    # Remplacer par les méthodes existantes
    switch ($method) {
        'ValidateStrongTrendDirection' { 
            $content = $content -replace $method, 'ValidateTrendDirection'
        }
        'ValidateAdvancedPullback' { 
            $content = $content -replace $method, 'ValidatePullbackPattern'
        }
        'ValidateStrongDojiConfirmation' { 
            $content = $content -replace $method, 'ValidateDojiConfirmation'
        }
        'ValidateAdvancedVolumeCondition' { 
            $content = $content -replace $method, 'ValidateVolumeCondition'
        }
        'ValidateStrongMarketStructure' { 
            $content = $content -replace $method, 'ValidateMarketStructure'
        }
        'ValidateOptimalTiming' { 
            $content = $content -replace $method, 'ValidatePriceActionConfirmation'
        }
    }
}

# Correction des appels aux méthodes de validation intelligente
$content = $content -replace 'CalculateIntelligentConfidenceScore\(', 'CalculateConfidenceScore('

# Suppression des méthodes en double ou incorrectes
$content = $content -replace '(?s)//\+------------------------------------------------------------------\+\r?\n//\| Validation Multi-Timeframe Alignment.*?return total_score;\r?\n}', ''

# Sauvegarde du fichier corrigé
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8

Write-Host "Corrections d'intégration appliquées avec succès!"
Write-Host "Les méthodes de validation ont été corrigées pour utiliser les méthodes existantes."
