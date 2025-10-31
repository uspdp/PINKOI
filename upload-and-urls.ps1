$RepoOwner = "usdp"
$RepoName  = "PINKOI"
$Branch    = "main"
$ImageDir  = "images"

$RepoPath = (Get-Location).Path
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host "git not found"; exit 1 }

# Collect files (allow empty push; still make CSV if files exist)
$files = Get-ChildItem -Path $ImageDir -File -Recurse -ErrorAction SilentlyContinue

# Commit & push (ignore "nothing to commit")
git add $ImageDir *> $null
$null = git commit -m ("images: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) 2>$null
git push origin $Branch

# Build URLs only when files exist
if ($files -and $files.Count -gt 0) {
  $sha = (git rev-parse HEAD).Trim()
  $rows = foreach ($f in $files) {
    $rel = $f.FullName.Substring($RepoPath.Length + 1).Replace('\','/')
    [PSCustomObject]@{
      file           = $rel
      jsDelivr_live  = "https://cdn.jsdelivr.net/gh/$RepoOwner/$RepoName@$Branch/$rel"
      jsDelivr_lock  = "https://cdn.jsdelivr.net/gh/$RepoOwner/$RepoName@$sha/$rel"
    }
  }
  $csv = Join-Path $RepoPath "urls.csv"
  $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
  Write-Host ("DONE. Wrote " + $csv)
} else {
  Write-Host "No files under 'images'. Add images then run again."
}
