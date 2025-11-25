param(
    [string]$OutputFolder = "C:\Users\Wesley\TestSite\brochures"
)

function Escape-PdfText {
    param([string]$Text)
    $Text -replace "\\", "\\\\" -replace "\(", "\\(" -replace "\)", "\\)"
}

function New-PlaceholderPdf {
    param(
        [string]$Path,
        [string]$Programme
    )

    $encoding = [System.Text.Encoding]::ASCII
    $header = "%PDF-1.4`n"

    $objects = @()
    $objects += "1 0 obj`n<< /Type /Catalog /Pages 2 0 R >>`nendobj`n`n"
    $objects += "2 0 obj`n<< /Type /Pages /Kids [3 0 R] /Count 1 >>`nendobj`n`n"
    $objects += "3 0 obj`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>`nendobj`n`n"

    $lines = @(
        "Placeholder brochure download",
        $Programme,
        "Replace this PDF with your official brochure."
    )

    $streamLines = @(
        "BT",
        "/F1 18 Tf",
        "72 720 Td",
        "(" + (Escape-PdfText $lines[0]) + ") Tj",
        "0 -28 Td",
        "(" + (Escape-PdfText $lines[1]) + ") Tj",
        "0 -28 Td",
        "(" + (Escape-PdfText $lines[2]) + ") Tj",
        "ET"
    )

    $streamData = ($streamLines -join "`n") + "`n"
    $length = $encoding.GetByteCount($streamData)

    $objects += "4 0 obj`n<< /Length $length >>`nstream`n$streamData`nendstream`nendobj`n`n"
    $objects += "5 0 obj`n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>`nendobj`n`n"

    $currentOffset = $encoding.GetByteCount($header)
    $offsets = @()

    foreach ($obj in $objects) {
        $offsets += $currentOffset
        $currentOffset += $encoding.GetByteCount($obj)
    }

    $xrefOffset = $currentOffset

    $xref = "xref`n0 6`n0000000000 65535 f `n"
    for ($i = 0; $i -lt $offsets.Length; $i++) {
        $xref += ("{0:0000000000}" -f $offsets[$i]) + " 00000 n `n"
    }

    $trailer = "trailer`n<< /Size 6 /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF"

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append($header)
    foreach ($obj in $objects) {
        [void]$builder.Append($obj)
    }
    [void]$builder.Append($xref)
    [void]$builder.Append($trailer)

    $bytes = $encoding.GetBytes($builder.ToString())
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$programmes = @{
    "software-developer-placeholder.pdf" = "Software Developer (18 months)"
    "ai-developer-placeholder.pdf" = "AI Developer (18 months)"
    "bootcamp-placeholder.pdf" = "Full Stack Web Developer Bootcamp (3 months)"
}

foreach ($entry in $programmes.GetEnumerator()) {
    $targetPath = Join-Path $OutputFolder $entry.Key
    New-PlaceholderPdf -Path $targetPath -Programme $entry.Value
}
