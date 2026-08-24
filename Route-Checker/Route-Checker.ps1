# ============================================================
# Route Checker
# Network Route Diagnostic Tool
# Compatible with Windows PowerShell 5.1
# ============================================================

$ErrorActionPreference = "Continue"

# ============================================================
# CONFIGURATION
# ============================================================

$debugAtivo = $false

# ============================================================
# LANGUAGE MESSAGES
# ============================================================

$msg = @{
    pt = @{
        title = "Verificador de Rota - Internet"

        chooseLanguage = "Escolha o idioma"
        destination = "Digite o IP ou dominio de destino"
        defaultDestination = "ENTER para usar 200.160.2.3 - NIC.br"

        detectingCountry = "Detectando pais de origem..."
        sourceCountry = "Pais de origem"
        countryUnavailable = "Nao foi possivel identificar o pais de origem."

        running = "Executando TRACERT..."
        completed = "Rastreamento concluido."

        lookingUp = "Consultando IP"
        locationUnknown = "Localizacao nao identificada."

        countries = "Paises identificados na rota"
        international = "Rota internacional detectada."
        localRoute = "Nenhum pais estrangeiro foi identificado na rota."
        firstForeign = "Primeiro pais estrangeiro identificado"
        correspondingHop = "Salto correspondente"

        ip = "IP"
        city = "Cidade"
        region = "Regiao"
        organization = "Organizacao"
        asn = "ASN"

        completeTrace = "Saida completa do TRACERT"

        privateIgnored = "IP privado ignorado"
        queryError = "Erro na consulta"

        pressEnter = "Pressione ENTER para sair"
    }

    en = @{
        title = "Route Checker - Internet"

        chooseLanguage = "Choose language"
        destination = "Enter the destination IP or domain"
        defaultDestination = "ENTER to use 200.160.2.3 - NIC.br"

        detectingCountry = "Detecting source country..."
        sourceCountry = "Source country"
        countryUnavailable = "Unable to identify source country."

        running = "Running TRACERT..."
        completed = "Route tracing completed."

        lookingUp = "Looking up IP"
        locationUnknown = "Location not identified."

        countries = "Countries identified in route"
        international = "International route detected."
        localRoute = "No foreign country was identified in the route."
        firstForeign = "First foreign country identified"
        correspondingHop = "Corresponding hop"

        ip = "IP"
        city = "City"
        region = "Region"
        organization = "Organization"
        asn = "ASN"

        completeTrace = "Complete TRACERT output"

        privateIgnored = "Private IP ignored"
        queryError = "Query error"

        pressEnter = "Press ENTER to exit"
    }
}

# ============================================================
# LANGUAGE SELECTION
# ============================================================

Clear-Host

Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host "              ROUTE CHECKER" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host

Write-Host "[1] Portugues"
Write-Host "[2] English"
Write-Host

do {
    $languageOption = Read-Host "Escolha / Choose"
} while ($languageOption -ne "1" -and $languageOption -ne "2")

if ($languageOption -eq "2") {
    $language = "en"
}
else {
    $language = "pt"
}

$Host.UI.RawUI.WindowTitle = $msg[$language].title

# ============================================================
# PRIVATE IP CHECK
# ============================================================

function Test-PrivateIP {

    param (
        [string]$IP
    )

    if ($IP -match '^127\.') {
        return $true
    }

    if ($IP -match '^10\.') {
        return $true
    }

    if ($IP -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') {
        return $true
    }

    if ($IP -match '^192\.168\.') {
        return $true
    }

    if ($IP -match '^169\.254\.') {
        return $true
    }

    if ($IP -match '^100\.(6[4-9]|[7-9][0-9])\.') {
        return $true
    }

    return $false
}

# ============================================================
# IP GEOLOCATION
# ============================================================

function Get-IPLocation {

    param (
        [string]$IP
    )

    try {

        $url = "https://ipapi.co/$IP/json/"

        $result = Invoke-RestMethod `
            -Uri $url `
            -Method Get `
            -TimeoutSec 5 `
            -ErrorAction Stop

        if ($result.country_code -and $result.country_name) {

            return [PSCustomObject]@{
                IP           = $IP
                CountryCode  = $result.country_code
                Country      = $result.country_name
                City         = $result.city
                Region       = $result.region
                Organization = $result.org
                ASN          = $result.asn
            }
        }

    }
    catch {

        if ($debugAtivo) {
            Write-Host "[DEBUG] $($msg[$language].queryError): $IP" -ForegroundColor DarkYellow
        }
    }

    return $null
}

# ============================================================
# SOURCE COUNTRY
# ============================================================

function Get-SourceCountry {

    try {

        $result = Invoke-RestMethod `
            -Uri "https://ipapi.co/json/" `
            -Method Get `
            -TimeoutSec 5 `
            -ErrorAction Stop

        if ($result.ip) {
            return Get-IPLocation -IP $result.ip
        }

    }
    catch {

        if ($debugAtivo) {
            Write-Host "[DEBUG] $($msg[$language].queryError)" -ForegroundColor DarkYellow
        }
    }

    return $null
}

# ============================================================
# DETECT SOURCE
# ============================================================

Clear-Host

Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host "   $($msg[$language].title)" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host

Write-Host $msg[$language].detectingCountry -ForegroundColor Gray

$source = Get-SourceCountry

$sourceCountryCode = $null
$sourceCountryName = $null

if ($source) {

    $sourceCountryCode = $source.CountryCode
    $sourceCountryName = $source.Country

    Write-Host
    Write-Host "$($msg[$language].sourceCountry): $sourceCountryName ($sourceCountryCode)" -ForegroundColor Green

}
else {

    Write-Host
    Write-Host $msg[$language].countryUnavailable -ForegroundColor Yellow
}

# ============================================================
# DESTINATION
# ============================================================

Write-Host

$destination = Read-Host "$($msg[$language].destination) - $($msg[$language].defaultDestination)"

if ([string]::IsNullOrWhiteSpace($destination)) {
    $destination = "200.160.2.3"
}

# ============================================================
# START TRACERT
# ============================================================

Clear-Host

Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host "   $($msg[$language].title)" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host

if ($sourceCountryName) {
    Write-Host "$($msg[$language].sourceCountry): $sourceCountryName ($sourceCountryCode)" -ForegroundColor Green
}

Write-Host "Destination: $destination" -ForegroundColor White
Write-Host

# ============================================================
# TRACERT
# ============================================================

Write-Host $msg[$language].running -ForegroundColor Yellow
Write-Host

$tracert = @()

try {

    $tracert = @(

        & "$env:SystemRoot\System32\tracert.exe" `
            -d `
            -h 20 `
            -w 1000 `
            $destination

    )

}
catch {

    Write-Host
    Write-Host "ERROR: Unable to execute TRACERT." -ForegroundColor Red

    Write-Host $_.Exception.Message -ForegroundColor Yellow

    Read-Host $msg[$language].pressEnter

    exit
}

Write-Host
Write-Host $msg[$language].completed -ForegroundColor Green

# ============================================================
# ANALYSIS
# ============================================================

$countries = @()
$analyzedIPs = @()

$firstForeignCountry = $null
$firstForeignHop = $null

$unknownLocation = $false

# ============================================================
# PROCESS TRACERT
# ============================================================

foreach ($line in $tracert) {

    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    if ($debugAtivo) {

        Write-Host
        Write-Host "[DEBUG] $line" -ForegroundColor DarkGray
    }

    $matches = [regex]::Matches(
        [string]$line,
        '\b(?:\d{1,3}\.){3}\d{1,3}\b'
    )

    foreach ($match in $matches) {

        $ip = $match.Value

        if ($analyzedIPs -contains $ip) {
            continue
        }

        $analyzedIPs += $ip

        if (Test-PrivateIP -IP $ip) {

            if ($debugAtivo) {
                Write-Host "[DEBUG] $($msg[$language].privateIgnored): $ip" -ForegroundColor DarkGray
            }

            continue
        }

        Write-Host
        Write-Host "$($msg[$language].lookingUp): $ip" -ForegroundColor DarkGray

        $location = Get-IPLocation -IP $ip

        if ($null -eq $location) {

            Write-Host "   $($msg[$language].locationUnknown)" -ForegroundColor Yellow

            $unknownLocation = $true

            continue
        }

        if ($countries -notcontains $location.Country) {
            $countries += $location.Country
        }

        Write-Host
        Write-Host "   $($location.Country)" -ForegroundColor Cyan
        Write-Host "   $($msg[$language].ip): $ip" -ForegroundColor Gray

        if ($location.City) {
            Write-Host "   $($msg[$language].city): $($location.City)" -ForegroundColor Gray
        }

        if ($location.Region) {
            Write-Host "   $($msg[$language].region): $($location.Region)" -ForegroundColor Gray
        }

        if ($location.Organization) {
            Write-Host "   $($msg[$language].organization): $($location.Organization)" -ForegroundColor Gray
        }

        if ($location.ASN) {
            Write-Host "   $($msg[$language].asn): $($location.ASN)" -ForegroundColor Gray
        }

        if (
            $sourceCountryCode `
            -and $location.CountryCode `
            -and $location.CountryCode -ne $sourceCountryCode `
            -and $null -eq $firstForeignCountry
        ) {

            $firstForeignCountry = $location.Country
            $firstForeignHop = $line
        }
    }
}

# ============================================================
# FINAL RESULT
# ============================================================

Write-Host
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host "RESULT" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor DarkGray

Write-Host

if ($sourceCountryName) {

    Write-Host "$($msg[$language].sourceCountry): $sourceCountryName ($sourceCountryCode)" -ForegroundColor Green
}

# ============================================================
# COUNTRIES
# ============================================================

if ($countries.Count -gt 0) {

    Write-Host
    Write-Host $msg[$language].countries -ForegroundColor Cyan

    foreach ($country in $countries) {
        Write-Host "   - $country" -ForegroundColor Gray
    }
}

# ============================================================
# ROUTE RESULT
# ============================================================

Write-Host

if ($firstForeignCountry) {

    Write-Host $msg[$language].international -ForegroundColor Yellow

    Write-Host
    Write-Host "$($msg[$language].firstForeign): $firstForeignCountry" -ForegroundColor Yellow

    Write-Host
    Write-Host "$($msg[$language].correspondingHop):" -ForegroundColor Cyan

    Write-Host $firstForeignHop -ForegroundColor Gray

}
elseif ($unknownLocation) {

    Write-Host $msg[$language].locationUnknown -ForegroundColor Yellow

}
else {

    Write-Host $msg[$language].localRoute -ForegroundColor Green
}

# ============================================================
# COMPLETE TRACERT
# ============================================================

Write-Host
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host $msg[$language].completeTrace -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host

if ($tracert.Count -gt 0) {

    foreach ($line in $tracert) {
        Write-Host $line
    }

}
else {

    Write-Host "TRACERT returned no data." -ForegroundColor Red
}

# ============================================================
# END
# ============================================================

Write-Host
Write-Host "===================================================" -ForegroundColor DarkGray
Write-Host

Read-Host $msg[$language].pressEnter