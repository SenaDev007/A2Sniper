$patternDetectorPath = "Include\PatternDetector.mqh"
$content = Get-Content -Path $patternDetectorPath -Raw

# Ajout de l'include pour le système intelligent
if ($content -notmatch '#include "IntelligentPatternDetector.mqh"') {
    $includeRegex = '(?m)^(#include.*?\n)'
    $includeMatch = [regex]::Match($content, $includeRegex)
    if ($includeMatch.Success) {
        $lastInclude = $includeMatch.Groups[1].Value
        $newInclude = $lastInclude + '#include "IntelligentPatternDetector.mqh"' + "`n"
        $content = $content -replace [regex]::Escape($lastInclude), $newInclude
    }
}

# Ajout de l'instance du détecteur intelligent dans la classe
$privateRegex = '(?s)(class CPatternDetector\s*\{.*?private:)'
if ($content -match $privateRegex) {
    $privateMatch = $matches[1]
    $newPrivate = $privateMatch + "`n    // Instance du détecteur intelligent`n    CIntelligentPatternDetector* m_intelligent_detector;`n"
    $content = $content -replace [regex]::Escape($privateMatch), $newPrivate
}

# Modification du constructeur
$constructorRegex = '(?s)(CPatternDetector::CPatternDetector\(\)\s*\{[^}]*)\}'
if ($content -match $constructorRegex) {
    $constructorBody = $matches[1]
    $newConstructor = $constructorBody + "`n    m_intelligent_detector = new CIntelligentPatternDetector();`n}"
    $content = $content -replace [regex]::Escape($matches[0]), $newConstructor
}

# Modification du destructeur
$destructorRegex = '(?s)(CPatternDetector::~CPatternDetector\(\)\s*\{[^}]*)\}'
if ($content -match $destructorRegex) {
    $destructorBody = $matches[1]
    $newDestructor = $destructorBody + "`n    if(m_intelligent_detector != NULL) {`n        delete m_intelligent_detector;`n        m_intelligent_detector = NULL;`n    }`n}"
    $content = $content -replace [regex]::Escape($matches[0]), $newDestructor
}

# Sauvegarde du fichier modifié
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8

Write-Host "Structure de base du système intelligent ajoutée avec succès"

# Maintenant, ajoutons les méthodes de validation intelligente
$intelligentMethodsContent = Get-Content -Path "intelligent_validation_methods.mqh" -Raw
$content += "`n`n// ===== MÉTHODES DE VALIDATION INTELLIGENTE =====`n"
$content += $intelligentMethodsContent

# Sauvegarde finale
$content | Set-Content -Path $patternDetectorPath -Encoding UTF8

Write-Host "Système de détection intelligent intégré avec succès!"
Write-Host "Prêt pour des tests avec 95% de précision cible"
