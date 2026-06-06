# Archer Tsai

Personal website hosted with GitHub Pages.

## Photo management

Photo publishing runs locally and does not ask for or store a GitHub personal
access token.

Replace the profile photo:

```powershell
.\tools\update-photo.ps1 -Mode Profile -ImagePath "C:\path\photo.jpg"
```

Add a gallery photo:

```powershell
.\tools\update-photo.ps1 -Mode Gallery -ImagePath "C:\path\photo.jpg" -Caption "Photo caption"
```

Add `-Publish` to stage, commit, and push the resulting files through the
computer's existing Git authentication. Images are resized to a maximum of
1600 pixels and rewritten without EXIF metadata.

## Security

Run the repository scanner before publishing:

```powershell
.\tools\security-scan.ps1
```

The local pre-commit hook can be enabled with:

```powershell
git config core.hooksPath .githooks
```

Do not commit original photos, resumes, certificate scans, private keys,
environment files, access tokens, email addresses, phone numbers, signatures,
or credential verification numbers.
